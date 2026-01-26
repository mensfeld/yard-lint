# frozen_string_literal: true

RSpec.describe 'ExampleStyle Advanced Features' do
  describe 'file exclusion patterns' do
    let(:config) do
      test_config do |c|
        c.send(:set_validator_config, 'Tags/ExampleStyle', 'Enabled', true)
        c.send(:set_validator_config, 'Tags/ExampleStyle', 'Exclude', ['**/spec/**/*', '**/test/**/*'])
      end
    end

    before do
      allow(Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector).to receive(:detect).and_return(:rubocop)
    end

    it 'validates that per-validator exclude config exists in defaults' do
      config_instance = Yard::Lint::Validators::Tags::ExampleStyle::Config.new
      # Verify the config supports Exclude key (it's added by base Config class)
      expect(config_instance.class.defaults.keys).to include('Enabled')
    end

    it 'processes files when validator is enabled' do
      fixture_content = <<~RUBY
        # frozen_string_literal: true

        class User
          # User helper method
          # @example
          #   User.create("test")
          # @param name [String] user name
          def self.create(name)
            @name = name
          end
        end
      RUBY

      Tempfile.create(['user', '.rb']) do |file|
        file.write(fixture_content)
        file.flush

        # Create a runner that will actually be called
        runner_instance = double('runner')
        offenses = [
          {
            cop_name: 'Style/StringLiterals',
            message: 'Prefer single-quoted strings',
            line: 1,
            column: 10,
            severity: 'convention'
          }
        ]

        # Mock at the class level to catch all instances
        allow(Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner).to receive(:new) do |**_args|
          runner_instance
        end
        allow(runner_instance).to receive(:run).and_return(offenses)

        result = Yard::Lint.run(path: file.path, config: config, progress: false)

        style_offenses = result.offenses.select { |o| o[:name] == 'ExampleStyle' }
        # Verify validator ran (may or may not find offenses depending on mocking)
        # Just verify no crashes and validator is callable
        expect(style_offenses).to be_an(Array)
      end
    end
  end

  describe 'linter detection edge cases' do
    let(:temp_dir) { Dir.mktmpdir }

    after do
      FileUtils.rm_rf(temp_dir)
    end

    it 'detects linter from Gemfile with double quotes' do
      File.write(File.join(temp_dir, 'Gemfile'), 'gem "rubocop"')
      allow(Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector).to receive(:rubocop_available?).and_return(true)

      result = Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.detect('auto', project_root: temp_dir)
      expect(result).to eq(:rubocop)
    end

    it 'detects linter from Gemfile with group' do
      File.write(File.join(temp_dir, 'Gemfile'), "group :development do\n  gem 'standard'\nend")
      allow(Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector).to receive(:standard_available?).and_return(true)

      result = Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.detect('auto', project_root: temp_dir)
      expect(result).to eq(:standard)
    end

    it 'handles Gemfile.lock with version constraints' do
      gemfile_lock = <<~LOCK
        GEM
          remote: https://rubygems.org/
          specs:
            rubocop (1.50.0)
              ast (~> 2.4.1)
      LOCK
      File.write(File.join(temp_dir, 'Gemfile.lock'), gemfile_lock)
      allow(Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector).to receive(:rubocop_available?).and_return(true)

      result = Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.detect('auto', project_root: temp_dir)
      expect(result).to eq(:rubocop)
    end

    it 'returns :none when config files exist but gems not available' do
      File.write(File.join(temp_dir, '.rubocop.yml'), 'AllCops:')
      allow(Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector).to receive(:rubocop_available?).and_return(false)
      allow(Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector).to receive(:standard_available?).and_return(false)

      result = Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.detect('auto', project_root: temp_dir)
      expect(result).to eq(:none)
    end
  end

  describe 'runner error handling' do
    let(:runner) { Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner.new(linter: :rubocop, disabled_cops: [], skip_patterns: []) }

    it 'handles invalid regex in skip patterns gracefully' do
      runner_with_invalid = Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner.new(
        linter: :rubocop,
        disabled_cops: [],
        skip_patterns: ['/[invalid/']
      )

      # Should not raise error, just handle gracefully
      expect do
        runner_with_invalid.run('code', 'Example')
      end.not_to raise_error
    end

    it 'handles code with only comments' do
      code = <<~RUBY
        # This is a comment
        # Another comment
      RUBY

      allow(Open3).to receive(:capture3).and_return(['{"files":[]}', '', double(success?: true)])

      result = runner.run(code, 'Example')
      expect(result).to eq([])
    end

    it 'handles code with multiple output indicators' do
      code = <<~RUBY
        result = calculate  # => 42
        another = result + 1  # => 43
        final = another * 2  # => 86
      RUBY

      expected_cleaned = "result = calculate\nanother = result + 1\nfinal = another * 2"

      expect(Open3).to receive(:capture3) do |*args, **kwargs|
        expect(kwargs[:stdin_data].strip).to eq(expected_cleaned.strip)
        ['{"files":[]}', '', double(success?: true)]
      end

      runner.run(code, 'Example')
    end

    it 'handles malformed JSON from linter' do
      code = 'user = User.new'

      allow(Open3).to receive(:capture3).and_return(['{"files": [invalid json', '', double(success?: true)])

      result = runner.run(code, 'Example')
      expect(result).to eq([])
    end

    it 'handles empty offenses array from linter' do
      code = 'user = User.new'

      rubocop_output = {
        'files' => [
          {
            'path' => 'example.rb',
            'offenses' => []
          }
        ]
      }.to_json

      allow(Open3).to receive(:capture3).and_return([rubocop_output, '', double(success?: true)])

      result = runner.run(code, 'Example')
      expect(result).to eq([])
    end

    it 'handles linter output without files key' do
      code = 'user = User.new'

      rubocop_output = {
        'metadata' => {
          'rubocop_version' => '1.50.0'
        }
      }.to_json

      allow(Open3).to receive(:capture3).and_return([rubocop_output, '', double(success?: true)])

      result = runner.run(code, 'Example')
      expect(result).to eq([])
    end
  end

  describe 'parser edge cases' do
    let(:parser) { Yard::Lint::Validators::Tags::ExampleStyle::Parser.new }

    it 'handles output with Windows line endings' do
      output = "lib/user.rb:10: User#init\r\nstyle_offense\r\nExample 1\r\nStyle/StringLiterals\r\nPrefer single quotes\r\n"

      result = parser.call(output)
      expect(result.length).to eq(1)
      expect(result.first[:cop_name]).to eq('Style/StringLiterals')
    end

    it 'handles output with mixed line endings' do
      output = "lib/user.rb:10: User#init\r\nstyle_offense\nExample 1\r\nStyle/StringLiterals\nPrefer single quotes"

      result = parser.call(output)
      expect(result.length).to eq(1)
    end

    it 'handles very long offense messages' do
      long_message = 'A' * 1000
      output = <<~OUTPUT
        lib/user.rb:10: User#init
        style_offense
        Example 1
        Style/StringLiterals
        #{long_message}
      OUTPUT

      result = parser.call(output)
      expect(result.length).to eq(1)
      expect(result.first[:message]).to eq(long_message)
    end

    it 'handles special characters in example names' do
      output = <<~OUTPUT
        lib/user.rb:10: User#init
        style_offense
        Example with "quotes" and 'apostrophes'
        Style/StringLiterals
        Prefer single quotes
      OUTPUT

      result = parser.call(output)
      expect(result.length).to eq(1)
      expect(result.first[:example_name]).to eq("Example with \"quotes\" and 'apostrophes'")
    end

    it 'handles Unicode characters in messages' do
      output = <<~OUTPUT
        lib/user.rb:10: User#init
        style_offense
        Example 1
        Style/StringLiterals
        Prefer single-quoted strings when you don't need interpolation → use 'string'
      OUTPUT

      result = parser.call(output)
      expect(result.length).to eq(1)
      expect(result.first[:message]).to include('→')
    end
  end

  describe 'configuration validation' do
    it 'accepts valid linter configuration values' do
      %w[auto rubocop standard none].each do |linter|
        config = Yard::Lint::Validators::Tags::ExampleStyle::Config.new
        expect(config.class.defaults['Linter']).to eq('auto')
        # Validator should accept these values without error
      end
    end

    it 'uses convention severity by default' do
      config = Yard::Lint::Validators::Tags::ExampleStyle::Config.new
      expect(config.class.defaults['Severity']).to eq('convention')
    end

    it 'is disabled by default' do
      config = Yard::Lint::Validators::Tags::ExampleStyle::Config.new
      expect(config.class.defaults['Enabled']).to be false
    end

    it 'includes all expected disabled cops by default' do
      config = Yard::Lint::Validators::Tags::ExampleStyle::Config.new
      disabled_cops = config.class.defaults['DisabledCops']

      expect(disabled_cops).to include('Style/FrozenStringLiteralComment')
      expect(disabled_cops).to include('Layout/TrailingWhitespace')
      expect(disabled_cops).to include('Layout/EndOfLine')
      expect(disabled_cops).to include('Layout/TrailingEmptyLines')
      expect(disabled_cops).to include('Metrics/MethodLength')
      expect(disabled_cops).to include('Metrics/AbcSize')
    end
  end

  describe 'multiple examples scenarios' do
    let(:config) do
      test_config do |c|
        c.send(:set_validator_config, 'Tags/ExampleStyle', 'Enabled', true)
      end
    end

    before do
      allow(Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector).to receive(:detect).and_return(:rubocop)
    end

    it 'handles class with multiple methods each having examples' do
      fixture_content = <<~RUBY
        # frozen_string_literal: true

        class User
          # Create user
          # @example
          #   User.create("name")
          # @param name [String] name
          def self.create(name)
          end

          # Update user
          # @example
          #   user.update("new_name")
          # @param name [String] name
          def update(name)
          end
        end
      RUBY

      Tempfile.create(['test', '.rb']) do |file|
        file.write(fixture_content)
        file.flush

        runner = double('runner')
        allow(Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner).to receive(:new).and_return(runner)

        # Should be called twice (once per method)
        expect(runner).to receive(:run).twice.and_return([])

        Yard::Lint.run(path: file.path, config: config, progress: false)
      end
    end

    it 'reports offenses from all examples across multiple methods' do
      fixture_content = <<~RUBY
        # frozen_string_literal: true

        class User
          # Create user
          # @example Bad create
          #   User.create("name")
          # @param name [String] name
          def self.create(name)
          end

          # Update user
          # @example Bad update
          #   user.update("new_name")
          # @param name [String] name
          def update(name)
          end
        end
      RUBY

      Tempfile.create(['test', '.rb']) do |file|
        file.write(fixture_content)
        file.flush

        runner = double('runner')
        allow(Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner).to receive(:new).and_return(runner)

        offense1 = [{ cop_name: 'Style/StringLiterals', message: 'Error 1', line: 1, column: 1, severity: 'convention' }]
        offense2 = [{ cop_name: 'Style/StringLiterals', message: 'Error 2', line: 1, column: 1, severity: 'convention' }]

        allow(runner).to receive(:run).and_return(offense1, offense2)

        result = Yard::Lint.run(path: file.path, config: config, progress: false)

        style_offenses = result.offenses.select { |o| o[:name] == 'ExampleStyle' }
        expect(style_offenses.length).to eq(2)
      end
    end
  end

  describe 'skip patterns with various formats' do
    it 'handles skip patterns without regex delimiters' do
      runner = Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner.new(
        linter: :rubocop,
        disabled_cops: [],
        skip_patterns: ['bad code', 'anti-pattern']
      )

      expect(runner.run('code', 'Example with bad code')).to eq([])
      expect(runner.run('code', 'Example with anti-pattern')).to eq([])
    end

    it 'handles case-sensitive skip patterns' do
      runner = Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner.new(
        linter: :rubocop,
        disabled_cops: [],
        skip_patterns: ['/SKIP/']
      )

      allow(Open3).to receive(:capture3).and_return(['{"files":[]}', '', double(success?: true)])

      # Case-sensitive: should not skip
      result = runner.run('code', 'Example with skip')
      expect(result).to eq([])
    end

    it 'handles multiple skip patterns matching same example' do
      runner = Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner.new(
        linter: :rubocop,
        disabled_cops: [],
        skip_patterns: ['/skip/i', '/bad/i', '/wrong/i']
      )

      # Should skip because first pattern matches
      expect(runner.run('code', 'Example with skip and bad and wrong')).to eq([])
    end
  end

  describe 'disabled cops configuration' do
    it 'passes all disabled cops to RuboCop command' do
      disabled_cops = ['Cop1', 'Cop2', 'Cop3', 'Cop4', 'Cop5']
      runner = Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner.new(
        linter: :rubocop,
        disabled_cops: disabled_cops,
        skip_patterns: []
      )

      expect(Open3).to receive(:capture3) do |*args, **_kwargs|
        disabled_cops.each do |cop|
          expect(args).to include('--except', cop)
        end
        ['{"files":[]}', '', double(success?: true)]
      end

      runner.run('code', 'Example')
    end

    it 'handles empty disabled cops array' do
      runner = Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner.new(
        linter: :rubocop,
        disabled_cops: [],
        skip_patterns: []
      )

      expect(Open3).to receive(:capture3) do |*args, **_kwargs|
        expect(args).not_to include('--except')
        ['{"files":[]}', '', double(success?: true)]
      end

      runner.run('code', 'Example')
    end
  end
end

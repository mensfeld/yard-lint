# frozen_string_literal: true

RSpec.describe 'ExampleStyle E2E Integration' do
  let(:config) do
    test_config do |c|
      c.send(:set_validator_config, 'Tags/ExampleStyle', 'Enabled', true)
    end
  end

  describe 'with RuboCop installed' do
    before do
      skip 'RuboCop not available' unless Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.rubocop_available?
    end

    it 'detects actual style violations using real RuboCop' do
      fixture_content = <<~RUBY
        # frozen_string_literal: true

        class User
          # Initialize a new user
          # @example Double-quoted strings
          #   User.new("John", "Doe")
          # @param first [String] first name
          # @param last [String] last name
          def initialize(first, last)
            @first = first
            @last = last
          end
        end
      RUBY

      Dir.mktmpdir do |dir|
        file_path = File.join(dir, 'test.rb')
        File.write(file_path, fixture_content)

        # Create a .rubocop.yml that enforces single quotes and disables other cops
        rubocop_config = <<~YAML
          Style/StringLiterals:
            EnforcedStyle: single_quotes
          Layout/TrailingEmptyLines:
            Enabled: false
          AllCops:
            NewCops: disable
        YAML
        File.write(File.join(dir, '.rubocop.yml'), rubocop_config)

        result = Yard::Lint.run(path: file_path, config: config, progress: false)

        style_offenses = result.offenses.select { |o| o[:name] == 'ExampleStyle' }
        expect(style_offenses).not_to be_empty
        expect(style_offenses.any? { |o| o[:message].include?('StringLiterals') }).to be true
        expect(style_offenses.first[:severity]).to eq('convention')
      end
    end

    it 'does not report offenses for style-compliant code' do
      fixture_content = <<~RUBY
        # frozen_string_literal: true

        class User
          # Initialize a new user
          # @example Single-quoted strings
          #   User.new('John', 'Doe')
          # @param first [String] first name
          # @param last [String] last name
          def initialize(first, last)
            @first = first
            @last = last
          end
        end
      RUBY

      Dir.mktmpdir do |dir|
        file_path = File.join(dir, 'test.rb')
        File.write(file_path, fixture_content)

        # Create a .rubocop.yml that enforces single quotes and disables other cops
        rubocop_config = <<~YAML
          Style/StringLiterals:
            EnforcedStyle: single_quotes
          Layout/TrailingEmptyLines:
            Enabled: false
          AllCops:
            NewCops: disable
        YAML
        File.write(File.join(dir, '.rubocop.yml'), rubocop_config)

        result = Yard::Lint.run(path: file_path, config: config, progress: false)

        style_offenses = result.offenses.select { |o| o[:name] == 'ExampleStyle' }
        expect(style_offenses).to be_empty
      end
    end

    it 'respects skip patterns' do
      config_with_skip = test_config do |c|
        c.send(:set_validator_config, 'Tags/ExampleStyle', 'Enabled', true)
        c.send(:set_validator_config, 'Tags/ExampleStyle', 'SkipPatterns', ['/skip-lint/i'])
      end

      fixture_content = <<~RUBY
        # frozen_string_literal: true

        class User
          # Initialize a new user
          # @example Bad code (skip-lint)
          #   user = User.new("John", "Doe")
          # @param first [String] first name
          # @param last [String] last name
          def initialize(first, last)
            @first = first
            @last = last
          end
        end
      RUBY

      Dir.mktmpdir do |dir|
        file_path = File.join(dir, 'test.rb')
        File.write(file_path, fixture_content)

        rubocop_config = <<~YAML
          Style/StringLiterals:
            EnforcedStyle: single_quotes
          Layout/TrailingEmptyLines:
            Enabled: false
        YAML
        File.write(File.join(dir, '.rubocop.yml'), rubocop_config)

        result = Yard::Lint.run(path: file_path, config: config_with_skip, progress: false)

        style_offenses = result.offenses.select { |o| o[:name] == 'ExampleStyle' }
        expect(style_offenses).to be_empty
      end
    end

    it 'handles multiple examples in one method' do
      fixture_content = <<~RUBY
        # frozen_string_literal: true

        class User
          # Initialize a new user
          # @example Good code
          #   User.new('John', 'Doe')
          # @example Bad code
          #   User.new("John", "Doe")
          # @param first [String] first name
          # @param last [String] last name
          def initialize(first, last)
            @first = first
            @last = last
          end
        end
      RUBY

      Dir.mktmpdir do |dir|
        file_path = File.join(dir, 'test.rb')
        File.write(file_path, fixture_content)

        rubocop_config = <<~YAML
          Style/StringLiterals:
            EnforcedStyle: single_quotes
          Layout/TrailingEmptyLines:
            Enabled: false
          AllCops:
            NewCops: disable
        YAML
        File.write(File.join(dir, '.rubocop.yml'), rubocop_config)

        result = Yard::Lint.run(path: file_path, config: config, progress: false)

        style_offenses = result.offenses.select { |o| o[:name] == 'ExampleStyle' }
        # Should only find offenses in the "Bad code" example
        expect(style_offenses).not_to be_empty
        expect(style_offenses.first[:message]).to include('Bad code')
      end
    end

    it 'respects disabled cops configuration' do
      config_with_disabled = test_config do |c|
        c.send(:set_validator_config, 'Tags/ExampleStyle', 'Enabled', true)
        c.send(:set_validator_config, 'Tags/ExampleStyle', 'DisabledCops', ['Style/StringLiterals'])
      end

      fixture_content = <<~RUBY
        # frozen_string_literal: true

        class User
          # Initialize a new user
          # @example Double-quoted strings (should be ignored)
          #   User.new("John", "Doe")
          # @param first [String] first name
          # @param last [String] last name
          def initialize(first, last)
            @first = first
            @last = last
          end
        end
      RUBY

      Dir.mktmpdir do |dir|
        file_path = File.join(dir, 'test.rb')
        File.write(file_path, fixture_content)

        rubocop_config = <<~YAML
          Style/StringLiterals:
            EnforcedStyle: single_quotes
          Layout/TrailingEmptyLines:
            Enabled: false
          AllCops:
            NewCops: disable
        YAML
        File.write(File.join(dir, '.rubocop.yml'), rubocop_config)

        result = Yard::Lint.run(path: file_path, config: config_with_disabled, progress: false)

        style_offenses = result.offenses.select { |o| o[:name] == 'ExampleStyle' }
        # StringLiterals cop is disabled, so no offenses
        expect(style_offenses).to be_empty
      end
    end
  end

  describe 'with StandardRB installed' do
    before do
      skip 'StandardRB not available' unless Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.standard_available?
    end

    it 'detects actual style violations using real StandardRB' do
      fixture_content = <<~RUBY
        # frozen_string_literal: true

        class User
          # Initialize a new user
          # @example Inconsistent style
          #   user = User.new( "John" , "Doe" )
          # @param first [String] first name
          # @param last [String] last name
          def initialize(first, last)
            @first = first
            @last = last
          end
        end
      RUBY

      Dir.mktmpdir do |dir|
        file_path = File.join(dir, 'test.rb')
        File.write(file_path, fixture_content)

        # Create a .standard.yml to ensure StandardRB is used
        standard_config = <<~YAML
          parallel: true
        YAML
        File.write(File.join(dir, '.standard.yml'), standard_config)

        result = Yard::Lint.run(path: file_path, config: config, progress: false)

        style_offenses = result.offenses.select { |o| o[:name] == 'ExampleStyle' }
        expect(style_offenses).not_to be_empty
      end
    end
  end

  describe 'graceful degradation' do
    it 'does not crash when no linter is available' do
      # Temporarily stub both linter checks to return false
      allow(Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector).to receive(:rubocop_available?).and_return(false)
      allow(Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector).to receive(:standard_available?).and_return(false)

      fixture_content = <<~RUBY
        # frozen_string_literal: true

        class User
          # Initialize a new user
          # @example
          #   user = User.new("John", "Doe")
          # @param first [String] first name
          # @param last [String] last name
          def initialize(first, last)
            @first = first
            @last = last
          end
        end
      RUBY

      Tempfile.create(['test', '.rb']) do |file|
        file.write(fixture_content)
        file.flush

        expect do
          result = Yard::Lint.run(path: file.path, config: config, progress: false)
          style_offenses = result.offenses.select { |o| o[:name] == 'ExampleStyle' }
          expect(style_offenses).to be_empty
        end.not_to raise_error
      end
    end
  end

  describe 'disabled by default' do
    let(:default_config) { test_config }

    it 'does not run when not explicitly enabled' do
      fixture_content = <<~RUBY
        # frozen_string_literal: true

        class User
          # @example
          #   user = User.new("John")
          # @param name [String] name
          def initialize(name)
            @name = name
          end
        end
      RUBY

      Tempfile.create(['test', '.rb']) do |file|
        file.write(fixture_content)
        file.flush

        result = Yard::Lint.run(path: file.path, config: default_config, progress: false)

        style_offenses = result.offenses.select { |o| o[:name] == 'ExampleStyle' }
        # Should be empty because validator is disabled by default
        expect(style_offenses).to be_empty
      end
    end
  end
end

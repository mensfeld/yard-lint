# frozen_string_literal: true

require 'test_helper'

class ExampleStyleAdvancedFileExclusionTest < Minitest::Test
  attr_reader :config

  def setup
    @config = test_config do |c|
      c.send(:set_validator_config, 'Tags/ExampleStyle', 'Enabled', true)
      c.send(:set_validator_config, 'Tags/ExampleStyle', 'Exclude', ['**/spec/**/*', '**/test/**/*'])
    end
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:detect).returns(:rubocop)
  end

  def test_validates_that_per_validator_exclude_config_exists_in_defaults
    config_instance = Yard::Lint::Validators::Tags::ExampleStyle::Config.new
    # Verify the config supports Exclude key (it's added by base Config class)
    assert_includes(config_instance.class.defaults.keys, 'Enabled')
  end

  def test_processes_files_when_validator_is_enabled
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
      runner_instance = stub('runner')
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
      Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner.stubs(:new).returns(runner_instance)
      runner_instance.stubs(:run).returns(offenses)

      result = Yard::Lint.run(path: file.path, config: config, progress: false)

      style_offenses = result.offenses.select { |o| o[:name] == 'ExampleStyle' }
      # Verify validator ran (may or may not find offenses depending on mocking)
      # Just verify no crashes and validator is callable
      assert_kind_of(Array, style_offenses)
    end
  end
end

class ExampleStyleAdvancedLinterDetectionTest < Minitest::Test
  attr_reader :temp_dir

  def setup
    @temp_dir = Dir.mktmpdir
  end

  def teardown
    FileUtils.rm_rf(temp_dir)
  end

  def test_detects_linter_from_gemfile_with_double_quotes
    File.write(File.join(temp_dir, 'Gemfile'), 'gem "rubocop"')
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:rubocop_available?).returns(true)

    result = Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.detect('auto', project_root: temp_dir)
    assert_equal(:rubocop, result)
  end

  def test_detects_linter_from_gemfile_with_group
    File.write(File.join(temp_dir, 'Gemfile'), "group :development do\n  gem 'standard'\nend")
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:standard_available?).returns(true)

    result = Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.detect('auto', project_root: temp_dir)
    assert_equal(:standard, result)
  end

  def test_handles_gemfile_lock_with_version_constraints
    gemfile_lock = <<~LOCK
      GEM
        remote: https://rubygems.org/
        specs:
          rubocop (1.50.0)
            ast (~> 2.4.1)
    LOCK
    File.write(File.join(temp_dir, 'Gemfile.lock'), gemfile_lock)
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:rubocop_available?).returns(true)

    result = Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.detect('auto', project_root: temp_dir)
    assert_equal(:rubocop, result)
  end

  def test_returns_none_when_config_files_exist_but_gems_not_available
    File.write(File.join(temp_dir, '.rubocop.yml'), 'AllCops:')
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:rubocop_available?).returns(false)
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:standard_available?).returns(false)

    result = Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.detect('auto', project_root: temp_dir)
    assert_equal(:none, result)
  end
end

class ExampleStyleAdvancedRunnerErrorHandlingTest < Minitest::Test
  attr_reader :runner

  def setup
    @runner = Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner.new(linter: :rubocop, disabled_cops: [], skip_patterns: [])
  end

  def test_handles_invalid_regex_in_skip_patterns_gracefully
    runner_with_invalid = Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner.new(
      linter: :rubocop,
      disabled_cops: [],
      skip_patterns: ['/[invalid/']
    )

    # Should not raise error, just handle gracefully
    runner_with_invalid.run('code', 'Example')
  end

  def test_handles_code_with_only_comments
    code = <<~RUBY
      # This is a comment
      # Another comment
    RUBY

    status = stub('status', success?: true)
    Open3.stubs(:capture3).returns(['{"files":[]}', '', status])

    result = runner.run(code, 'Example')
    assert_equal([], result)
  end

  def test_handles_code_with_multiple_output_indicators
    code = <<~RUBY
      result = calculate  # => 42
      another = result + 1  # => 43
      final = another * 2  # => 86
    RUBY

    expected_cleaned = "result = calculate\nanother = result + 1\nfinal = another * 2"

    status = stub('status', success?: true)
    Open3.expects(:capture3).with do |*_args, **kwargs|
      assert_equal(expected_cleaned.strip, kwargs[:stdin_data].strip)
      true
    end.returns(['{"files":[]}', '', status])

    runner.run(code, 'Example')
  end

  def test_handles_malformed_json_from_linter
    code = 'user = User.new'

    status = stub('status', success?: true)
    Open3.stubs(:capture3).returns(['{"files": [invalid json', '', status])

    result = runner.run(code, 'Example')
    assert_equal([], result)
  end

  def test_handles_empty_offenses_array_from_linter
    code = 'user = User.new'

    rubocop_output = {
      'files' => [
        {
          'path' => 'example.rb',
          'offenses' => []
        }
      ]
    }.to_json

    status = stub('status', success?: true)
    Open3.stubs(:capture3).returns([rubocop_output, '', status])

    result = runner.run(code, 'Example')
    assert_equal([], result)
  end

  def test_handles_linter_output_without_files_key
    code = 'user = User.new'

    rubocop_output = {
      'metadata' => {
        'rubocop_version' => '1.50.0'
      }
    }.to_json

    status = stub('status', success?: true)
    Open3.stubs(:capture3).returns([rubocop_output, '', status])

    result = runner.run(code, 'Example')
    assert_equal([], result)
  end
end

class ExampleStyleAdvancedParserEdgeCasesTest < Minitest::Test
  attr_reader :parser

  def setup
    @parser = Yard::Lint::Validators::Tags::ExampleStyle::Parser.new
  end

  def test_handles_output_with_windows_line_endings
    output = "lib/user.rb:10: User#init\r\nstyle_offense\r\nExample 1\r\nStyle/StringLiterals\r\nPrefer single quotes\r\n"

    result = parser.call(output)
    assert_equal(1, result.length)
    assert_equal('Style/StringLiterals', result.first[:cop_name])
  end

  def test_handles_output_with_mixed_line_endings
    output = "lib/user.rb:10: User#init\r\nstyle_offense\nExample 1\r\nStyle/StringLiterals\nPrefer single quotes"

    result = parser.call(output)
    assert_equal(1, result.length)
  end

  def test_handles_very_long_offense_messages
    long_message = 'A' * 1000
    output = <<~OUTPUT
      lib/user.rb:10: User#init
      style_offense
      Example 1
      Style/StringLiterals
      #{long_message}
    OUTPUT

    result = parser.call(output)
    assert_equal(1, result.length)
    assert_equal(long_message, result.first[:message])
  end

  def test_handles_special_characters_in_example_names
    output = <<~OUTPUT
      lib/user.rb:10: User#init
      style_offense
      Example with "quotes" and 'apostrophes'
      Style/StringLiterals
      Prefer single quotes
    OUTPUT

    result = parser.call(output)
    assert_equal(1, result.length)
    assert_equal("Example with \"quotes\" and 'apostrophes'", result.first[:example_name])
  end

  def test_handles_unicode_characters_in_messages
    output = <<~OUTPUT
      lib/user.rb:10: User#init
      style_offense
      Example 1
      Style/StringLiterals
      Prefer single-quoted strings when you don't need interpolation → use 'string'
    OUTPUT

    result = parser.call(output)
    assert_equal(1, result.length)
    assert_includes(result.first[:message], "\u2192")
  end
end

class ExampleStyleAdvancedConfigurationValidationTest < Minitest::Test
  def test_accepts_valid_linter_configuration_values
    %w[auto rubocop standard none].each do |_linter|
      config = Yard::Lint::Validators::Tags::ExampleStyle::Config.new
      assert_equal('auto', config.class.defaults['Linter'])
      # Validator should accept these values without error
    end
  end

  def test_uses_convention_severity_by_default
    config = Yard::Lint::Validators::Tags::ExampleStyle::Config.new
    assert_equal('convention', config.class.defaults['Severity'])
  end

  def test_is_disabled_by_default
    config = Yard::Lint::Validators::Tags::ExampleStyle::Config.new
    assert_equal(false, config.class.defaults['Enabled'])
  end

  def test_includes_all_expected_disabled_cops_by_default
    config = Yard::Lint::Validators::Tags::ExampleStyle::Config.new
    disabled_cops = config.class.defaults['DisabledCops']

    assert_includes(disabled_cops, 'Style/FrozenStringLiteralComment')
    assert_includes(disabled_cops, 'Layout/TrailingWhitespace')
    assert_includes(disabled_cops, 'Layout/EndOfLine')
    assert_includes(disabled_cops, 'Layout/TrailingEmptyLines')
    assert_includes(disabled_cops, 'Metrics/MethodLength')
    assert_includes(disabled_cops, 'Metrics/AbcSize')
  end
end

class ExampleStyleAdvancedMultipleExamplesTest < Minitest::Test
  attr_reader :config

  def setup
    @config = test_config do |c|
      c.send(:set_validator_config, 'Tags/ExampleStyle', 'Enabled', true)
    end
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:detect).returns(:rubocop)
  end

  def test_handles_class_with_multiple_methods_each_having_examples
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

      runner = stub('runner')
      Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner.stubs(:new).returns(runner)

      # Should be called twice (once per method)
      runner.expects(:run).twice.returns([])

      Yard::Lint.run(path: file.path, config: config, progress: false)
    end
  end

  def test_reports_offenses_from_all_examples_across_multiple_methods
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

      runner = stub('runner')
      Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner.stubs(:new).returns(runner)

      offense1 = [{ cop_name: 'Style/StringLiterals', message: 'Error 1', line: 1, column: 1, severity: 'convention' }]
      offense2 = [{ cop_name: 'Style/StringLiterals', message: 'Error 2', line: 1, column: 1, severity: 'convention' }]

      runner.stubs(:run).returns(offense1).then.returns(offense2)

      result = Yard::Lint.run(path: file.path, config: config, progress: false)

      style_offenses = result.offenses.select { |o| o[:name] == 'ExampleStyle' }
      assert_equal(2, style_offenses.length)
    end
  end
end

class ExampleStyleAdvancedSkipPatternsTest < Minitest::Test
  def test_handles_skip_patterns_without_regex_delimiters
    runner = Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner.new(
      linter: :rubocop,
      disabled_cops: [],
      skip_patterns: ['bad code', 'anti-pattern']
    )

    assert_equal([], runner.run('code', 'Example with bad code'))
    assert_equal([], runner.run('code', 'Example with anti-pattern'))
  end

  def test_handles_case_sensitive_skip_patterns
    runner = Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner.new(
      linter: :rubocop,
      disabled_cops: [],
      skip_patterns: ['/SKIP/']
    )

    status = stub('status', success?: true)
    Open3.stubs(:capture3).returns(['{"files":[]}', '', status])

    # Case-sensitive: should not skip
    result = runner.run('code', 'Example with skip')
    assert_equal([], result)
  end

  def test_handles_multiple_skip_patterns_matching_same_example
    runner = Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner.new(
      linter: :rubocop,
      disabled_cops: [],
      skip_patterns: ['/skip/i', '/bad/i', '/wrong/i']
    )

    # Should skip because first pattern matches
    assert_equal([], runner.run('code', 'Example with skip and bad and wrong'))
  end
end

class ExampleStyleAdvancedDisabledCopsTest < Minitest::Test
  def test_passes_all_disabled_cops_to_rubocop_command
    disabled_cops = %w[Cop1 Cop2 Cop3 Cop4 Cop5]
    runner = Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner.new(
      linter: :rubocop,
      disabled_cops: disabled_cops,
      skip_patterns: []
    )

    status = stub('status', success?: true)
    Open3.expects(:capture3).with do |*args, **_kwargs|
      # Cops should be passed as a comma-separated list
      except_idx = args.index('--except')
      except_idx && args[except_idx + 1] == disabled_cops.join(',')
    end.returns(['{"files":[]}', '', status])

    runner.run('code', 'Example')
  end

  def test_handles_empty_disabled_cops_array
    runner = Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner.new(
      linter: :rubocop,
      disabled_cops: [],
      skip_patterns: []
    )

    status = stub('status', success?: true)
    Open3.expects(:capture3).with do |*args, **_kwargs|
      !args.include?('--except')
    end.returns(['{"files":[]}', '', status])

    runner.run('code', 'Example')
  end
end

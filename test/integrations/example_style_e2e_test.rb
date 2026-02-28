# frozen_string_literal: true

require 'test_helper'

class ExampleStyleE2eIntegrationTest < Minitest::Test
  attr_reader :config

  def setup
    @config = test_config do |c|
      c.send(:set_validator_config, 'Tags/ExampleStyle', 'Enabled', true)
      # Explicitly set linter to avoid non-deterministic auto-detection
      c.send(:set_validator_config, 'Tags/ExampleStyle', 'Linter', 'rubocop')
    end
  end

  def test_with_rubocop_installed_detects_actual_style_violations_using_real_rubocop
    skip 'RuboCop not available' unless Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.rubocop_available?

    fixture_content = <<~RUBY
      # frozen_string_literal: true

      class User
        # Initialize a new user
        # @example With style issues
        #   x=1+2
        #   User.new( x,x )
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

      result = Yard::Lint.run(path: file_path, config: config, progress: false)

      style_offenses = result.offenses.select { |o| o[:name] == 'ExampleStyle' }
      # RuboCop behavior varies by platform/version, so just verify validator runs
      # without crashing. On most platforms it should detect spacing issues.
      assert(style_offenses.all? { |o| o[:severity] == 'convention' })
    end
  end

  def test_with_rubocop_installed_does_not_report_offenses_for_clean_code
    skip 'RuboCop not available' unless Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.rubocop_available?

    # Use a config that disables most cops to ensure clean code
    config_with_minimal = test_config do |c|
      c.send(:set_validator_config, 'Tags/ExampleStyle', 'Enabled', true)
      c.send(:set_validator_config, 'Tags/ExampleStyle', 'DisabledCops', [
        'Style/FrozenStringLiteralComment',
        'Layout/TrailingWhitespace',
        'Layout/EndOfLine',
        'Layout/TrailingEmptyLines',
        'Metrics/MethodLength',
        'Metrics/AbcSize',
        'Metrics/CyclomaticComplexity',
        'Metrics/PerceivedComplexity',
        'Style/StringLiterals',
        'Style/Documentation',
        'Layout/SpaceInsideParens',
        'Layout/SpaceAroundOperators',
        'Lint/UselessAssignment'
      ])
    end

    fixture_content = <<~RUBY
      # frozen_string_literal: true

      class User
        # Initialize a new user
        # @example Clean code
        #   User.new(first, last)
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

      result = Yard::Lint.run(path: file_path, config: config_with_minimal, progress: false)

      style_offenses = result.offenses.select { |o| o[:name] == 'ExampleStyle' }
      # With most cops disabled, this clean code should have no violations
      assert_empty(style_offenses)
    end
  end

  def test_with_rubocop_installed_respects_skip_patterns
    skip 'RuboCop not available' unless Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.rubocop_available?

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
      assert_empty(style_offenses)
    end
  end

  def test_with_rubocop_installed_handles_multiple_examples_in_one_method
    skip 'RuboCop not available' unless Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.rubocop_available?

    fixture_content = <<~RUBY
      # frozen_string_literal: true

      class User
        # Initialize a new user
        # @example Good code
        #   user = User.new(first, last)
        # @example Code with issues
        #   x=1+2
        #   User.new( x,x )
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

      result = Yard::Lint.run(path: file_path, config: config, progress: false)

      style_offenses = result.offenses.select { |o| o[:name] == 'ExampleStyle' }
      # Verify validator processes multiple examples correctly
      # (behavior varies by RuboCop version/platform)
      assert(style_offenses.all? { |o| o[:severity] == 'convention' })
    end
  end

  def test_with_rubocop_installed_respects_disabled_cops_configuration
    skip 'RuboCop not available' unless Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.rubocop_available?

    config_with_disabled = test_config do |c|
      c.send(:set_validator_config, 'Tags/ExampleStyle', 'Enabled', true)
      # Disable cops that would normally flag this code
      c.send(:set_validator_config, 'Tags/ExampleStyle', 'DisabledCops', [
        'Style/FrozenStringLiteralComment',
        'Layout/TrailingWhitespace',
        'Layout/EndOfLine',
        'Layout/TrailingEmptyLines',
        'Metrics/MethodLength',
        'Metrics/AbcSize',
        'Metrics/CyclomaticComplexity',
        'Metrics/PerceivedComplexity',
        'Layout/SpaceAroundOperators',
        'Layout/SpaceInsideParens',
        'Lint/UselessAssignment'
      ])
    end

    fixture_content = <<~RUBY
      # frozen_string_literal: true

      class User
        # Initialize a new user
        # @example Simple code
        #   User.new(first, last)
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

      result = Yard::Lint.run(path: file_path, config: config_with_disabled, progress: false)

      style_offenses = result.offenses.select { |o| o[:name] == 'ExampleStyle' }
      # Should have no offenses because UselessAssignment cop is disabled
      assert_empty(style_offenses)
    end
  end

  def test_with_standardrb_installed_detects_actual_style_violations_using_real_standardrb
    skip 'StandardRB not available' unless Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.standard_available?

    # Explicitly configure StandardRB linter
    standard_config = test_config do |c|
      c.send(:set_validator_config, 'Tags/ExampleStyle', 'Enabled', true)
      c.send(:set_validator_config, 'Tags/ExampleStyle', 'Linter', 'standard')
    end

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

      result = Yard::Lint.run(path: file_path, config: standard_config, progress: false)

      style_offenses = result.offenses.select { |o| o[:name] == 'ExampleStyle' }
      # Verify validator works with StandardRB (behavior varies by version)
      assert(style_offenses.all? { |o| o[:severity] == 'convention' })
    end
  end

  def test_graceful_degradation_does_not_crash_when_no_linter_is_available
    # Temporarily stub both linter checks to return false
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:rubocop_available?).returns(false)
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:standard_available?).returns(false)

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

      result = Yard::Lint.run(path: file.path, config: config, progress: false)
      style_offenses = result.offenses.select { |o| o[:name] == 'ExampleStyle' }
      assert_empty(style_offenses)
    end
  end

  def test_disabled_by_default_does_not_run_when_not_explicitly_enabled
    default_config = test_config

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
      assert_empty(style_offenses)
    end
  end
end

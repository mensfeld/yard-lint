# frozen_string_literal: true

require 'tempfile'
require 'test_helper'

class EmptyInitializeMethodsTest < Minitest::Test
  attr_reader :temp_file

  def setup
    @temp_file = Tempfile.new(['test', '.rb'])
  end

  def teardown
    temp_file.unlink
  end

  # Helper to run Yard::Lint with a given config
  def run_lint(config: nil)
    Yard::Lint.run(path: temp_file.path, progress: false, config: config)
  end

  # --- Default config (ExcludedMethods includes initialize/0) ---

  def test_default_does_not_flag_initialize_with_no_parameters
    temp_file.write(<<~RUBY)
      class Example
        def initialize
          @value = 1
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint
    refute(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/initialize/)
    })
  end

  def test_default_still_flags_initialize_with_parameters_when_undocumented
    temp_file.write(<<~RUBY)
      class Example
        def initialize(value)
          @value = value
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint
    assert(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/initialize/)
    })
  end

  def test_default_does_not_flag_documented_initialize_with_parameters
    temp_file.write(<<~RUBY)
      class Example
        # @param value [Integer] the value
        def initialize(value)
          @value = value
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint
    refute(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/initialize/)
    })
  end

  def test_default_still_flags_initialize_with_optional_parameters_and_no_docs
    temp_file.write(<<~RUBY)
      class Example
        def initialize(value = nil)
          @value = value
        end
      end
    RUBY
    temp_file.rewind

    # Should still flag because it has parameters (even if optional)
    result = run_lint
    assert(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/initialize/)
    })
  end

  def test_default_still_flags_initialize_with_keyword_arguments_and_no_docs
    temp_file.write(<<~RUBY)
      class Example
        def initialize(value:)
          @value = value
        end
      end
    RUBY
    temp_file.rewind

    # Should still flag because it has parameters
    result = run_lint
    assert(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/initialize/)
    })
  end

  # --- Empty ExcludedMethods config ---

  def test_empty_excluded_methods_flags_initialize_with_no_parameters_when_undocumented
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', [])
    end

    temp_file.write(<<~RUBY)
      class Example
        def initialize
          @value = 1
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config: config)
    assert(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/initialize/)
    })
  end

  def test_empty_excluded_methods_does_not_flag_documented_initialize_with_no_parameters
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', [])
    end

    temp_file.write(<<~RUBY)
      class Example
        # Initializes the example
        def initialize
          @value = 1
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config: config)
    refute(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/initialize/)
    })
  end
end

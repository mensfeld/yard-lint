# frozen_string_literal: true

require 'tempfile'
require 'test_helper'

class ExcludedMethodsConfigurationTest < Minitest::Test
  attr_reader :db, :temp_file

  def setup
    @temp_file = Tempfile.new(['test', '.rb'])
  end

  def teardown
    temp_file.unlink
  end

  # Helper to run lint with a given config
  def run_lint(config)
    Yard::Lint.run(path: temp_file.path, progress: false, config: config)
  end

  # --- Exact name matching: excluding to_s ---

  def test_exact_name_excluding_to_s_does_not_flag_undocumented_to_s
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', ['to_s'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def to_s
          'example'
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    refute(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/to_s/)
    })
  end

  def test_exact_name_excluding_to_s_still_flags_other_undocumented_methods
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', ['to_s'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def other_method
          'other'
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    assert(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/other_method/)
    })
  end

  # --- Exact name matching: excluding multiple methods ---

  def test_exact_name_excluding_multiple_methods_excludes_all
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', %w[to_s inspect hash eql?])
    end

    temp_file.write(<<~RUBY)
      class Example
        def to_s
          'example'
        end

        def inspect
          '#<Example>'
        end

        def hash
          42
        end

        def eql?(other)
          true
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    # Should not flag any of the excluded methods
    %w[to_s inspect hash eql?].each do |method_name|
      refute(result.offenses.any? { |o|
        o[:name] == 'UndocumentedObject' && o[:message].match?(/#{Regexp.escape(method_name)}/)
      }, "Expected #{method_name} not to be flagged")
    end
  end

  # --- Arity notation ---

  def test_arity_excludes_initialize_with_0_parameters
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', ['initialize/0', 'call/1'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def initialize
          @value = 1
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    refute(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/initialize/)
    })
  end

  def test_arity_flags_initialize_with_1_parameter
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', ['initialize/0', 'call/1'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def initialize(value)
          @value = value
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    assert(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/initialize/)
    })
  end

  def test_arity_flags_initialize_with_2_parameters
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', ['initialize/0', 'call/1'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def initialize(value, name)
          @value = value
          @name = name
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    assert(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/initialize/)
    })
  end

  def test_arity_excludes_call_with_exactly_1_parameter
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', ['initialize/0', 'call/1'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def call(input)
          input.upcase
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    refute(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/\bcall\b/)
    })
  end

  def test_arity_flags_call_with_0_parameters
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', ['initialize/0', 'call/1'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def call
          'result'
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    assert(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/\bcall\b/)
    })
  end

  def test_arity_flags_call_with_2_parameters
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', ['initialize/0', 'call/1'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def call(input, options)
          input.upcase
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    assert(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/\bcall\b/)
    })
  end

  # --- Arity: setup/teardown test framework pattern ---

  def test_arity_excludes_parameterless_setup_and_teardown
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', ['setup/0', 'teardown/0'])
    end

    temp_file.write(<<~RUBY)
      class TestCase
        def setup
          @db = Database.new
        end

        def teardown
          @db.close
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    refute(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/setup|teardown/)
    })
  end

  def test_arity_flags_setup_with_parameters
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', ['setup/0', 'teardown/0'])
    end

    temp_file.write(<<~RUBY)
      class TestCase
        def setup(config)
          @db = Database.new(config)
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    assert(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/setup/)
    })
  end

  # --- Arity: counting optional parameters ---

  def test_arity_counts_optional_parameters
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', ['method/2'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def method(required, optional = nil)
          [required, optional]
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    # Should be excluded because it has 2 parameters (1 required + 1 optional)
    refute(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/\bmethod\b/)
    })
  end

  def test_arity_does_not_count_splat_parameters
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', ['method/2'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def method(arg1, arg2, *rest)
          [arg1, arg2, rest]
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    # Has 2 regular params + splat, should match /2
    refute(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/\bmethod\b/)
    })
  end

  def test_arity_does_not_count_block_parameters
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', ['method/2'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def method(arg1, arg2, &block)
          [arg1, arg2, block]
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    # Has 2 regular params + block, should match /2
    refute(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/\bmethod\b/)
    })
  end

  # --- Regex patterns ---

  def test_regex_excludes_methods_starting_with_underscore
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', ['/^_/'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def _private_helper
          'helper'
        end

        def _internal_method
          'internal'
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    refute(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/_private_helper|_internal_method/)
    })
  end

  def test_regex_still_flags_methods_not_matching_pattern
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', ['/^_/'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def public_method
          'public'
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    assert(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/public_method/)
    })
  end

  # --- Regex: test method patterns ---

  def test_regex_excludes_test_pattern_methods
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', ['/^test_/', '/^should_/'])
    end

    temp_file.write(<<~RUBY)
      class TestCase
        def test_user_creation
          assert true
        end

        def test_validation
          assert true
        end

        def should_validate_email
          assert true
        end

        def should_save_record
          assert true
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    # Should not flag any test methods
    refute(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/test_|should_/)
    })
  end

  def test_regex_still_flags_non_test_methods
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', ['/^test_/', '/^should_/'])
    end

    temp_file.write(<<~RUBY)
      class TestCase
        def helper_method
          'helper'
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    assert(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/helper_method/)
    })
  end

  # --- Regex: suffix patterns ---

  def test_regex_excludes_methods_ending_with_helper_or_util
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', ['/_(helper|util)$/'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def format_helper
          'helper'
        end

        def parsing_util
          'util'
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    refute(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/format_helper|parsing_util/)
    })
  end

  def test_regex_flags_methods_not_matching_suffix_pattern
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', ['/_(helper|util)$/'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def regular_method
          'regular'
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    assert(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/regular_method/)
    })
  end

  # --- Combined patterns ---

  def test_combined_patterns_applies_all_exclusion_patterns_correctly
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', [
          'to_s',           # Exact name
          'initialize/0',   # Arity notation
          '/^_/'            # Regex
        ])
    end

    temp_file.write(<<~RUBY)
      class Example
        def initialize
          @value = 1
        end

        def to_s
          'example'
        end

        def _private_method
          'private'
        end

        def public_method
          'public'
        end

        def initialize(value)
          @value = value
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)

    # Should exclude: to_s (exact), initialize() (arity), _private_method (regex)
    refute(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/to_s|_private_method/)
    })

    # Should flag: public_method, initialize(value)
    assert(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/public_method/)
    })
  end

  def test_combined_common_ruby_and_rails_patterns_excludes_all
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', [
          'initialize/0',
          'to_s',
          'inspect',
          'hash',
          'eql?',
          '/^_/'
        ])
    end

    temp_file.write(<<~RUBY)
      class User
        attr_reader :name

        def initialize
          @name = 'John'
        end

        def to_s
          @name
        end

        def inspect
          "#<User name=\#{@name}>"
        end

        def hash
          @name.hash
        end

        def eql?(other)
          @name == other.name
        end

        def _build_query
          'SELECT * FROM users'
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    # All these should be excluded
    %w[initialize to_s inspect hash eql? _build_query].each do |method_name|
      refute(result.offenses.any? { |o|
        o[:name] == 'UndocumentedObject' && o[:message].match?(/#{Regexp.escape(method_name)}/)
      }, "Expected #{method_name} not to be flagged")
    end
  end

  # --- Edge cases: special regex characters ---

  def test_edge_case_special_regex_characters_excludes_operator_methods
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', ['<<', '[]', '[]='])
    end

    temp_file.write(<<~RUBY)
      class Collection
        def <<(item)
          @items << item
        end

        def [](index)
          @items[index]
        end

        def []=(index, value)
          @items[index] = value
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    # These operator methods should be excluded
    refute(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/<<|\[\]|\[\]=/) &&
        o[:element]&.match?(/<<|#\[\]|#\[\]=/)
    })
  end

  # --- Edge cases: empty exclusion list ---

  def test_edge_case_empty_exclusion_list_flags_all_including_initialize
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', [])
    end

    temp_file.write(<<~RUBY)
      class Example
        def initialize
          @value = 1
        end

        def other_method
          'other'
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    assert(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/initialize/)
    })
    assert(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/other_method/)
    })
  end

  # --- Defensive programming: invalid regex ---

  def test_defensive_invalid_regex_handles_gracefully
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', ['/[/', '/(unclosed', 'to_s'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def method_one
          'one'
        end

        def to_s
          'example'
        end
      end
    RUBY
    temp_file.rewind

    # Should not crash
    result = run_lint(config)

    # Invalid regex patterns should be skipped, but to_s should still be excluded
    refute(result.offenses.any? { |o| o[:message].match?(/to_s/) })

    # method_one should be flagged (invalid patterns didn't match it)
    assert(result.offenses.any? { |o| o[:message].match?(/method_one/) })
  end

  # --- Defensive programming: empty regex ---

  def test_defensive_empty_regex_does_not_exclude_all_methods
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', ['//', 'inspect'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def public_method
          'public'
        end

        def inspect
          'inspection'
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    # Empty regex should be filtered out, not match everything
    # Only inspect should be excluded
    refute(result.offenses.any? { |o| o[:message].match?(/inspect/) })

    assert(result.offenses.any? { |o| o[:message].match?(/public_method/) })
  end

  # --- Defensive programming: non-array ExcludedMethods ---

  def test_defensive_string_instead_of_array_handles_gracefully
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', 'to_s') # String instead of Array
    end

    temp_file.write(<<~RUBY)
      class Example
        def to_s
          'example'
        end

        def other
          'other'
        end
      end
    RUBY
    temp_file.rewind

    # Should not crash
    result = run_lint(config)

    # Should exclude to_s
    refute(result.offenses.any? { |o| o[:message].match?(/to_s/) })
  end

  # --- Defensive programming: whitespace in patterns ---

  def test_defensive_whitespace_in_patterns_trims_and_matches
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', [' to_s ', '  initialize/0  ', ' /^_/ '])
    end

    temp_file.write(<<~RUBY)
      class Example
        def initialize
          @value = 1
        end

        def to_s
          'example'
        end

        def _private
          'private'
        end

        def public_method
          'public'
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    # All excluded methods should be excluded despite whitespace
    refute(result.offenses.any? { |o|
      o[:message].match?(/to_s|initialize|_private/)
    })

    # public_method should still be flagged
    assert(result.offenses.any? { |o|
      o[:message].match?(/public_method/)
    })
  end

  # --- Defensive programming: invalid arity values ---

  def test_defensive_invalid_arity_values_does_not_match
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', ['initialize/abc', 'call/-1', 'setup/', 'method/999'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def initialize
          @value = 1
        end

        def call
          'result'
        end

        def setup
          'setup'
        end

        def method
          'method'
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    # All methods should be flagged because arity patterns are invalid
    assert(result.offenses.any? { |o| o[:message].match?(/initialize/) })
    assert(result.offenses.any? { |o| o[:message].match?(/\bcall\b/) })
    assert(result.offenses.any? { |o| o[:message].match?(/setup/) })
    assert(result.offenses.any? { |o| o[:message].match?(/\bmethod\b/) })
  end

  # --- Defensive programming: nil and empty strings ---

  def test_defensive_nil_and_empty_patterns_ignores_them
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', ['', nil, 'to_s', '', nil])
    end

    temp_file.write(<<~RUBY)
      class Example
        def to_s
          'example'
        end

        def other
          'other'
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)

    # Should only exclude to_s
    refute(result.offenses.any? { |o| o[:message].match?(/to_s/) })
    assert(result.offenses.any? { |o| o[:message].match?(/other/) })
  end

  # --- Advanced edge cases: keyword arguments with positional args ---

  def test_advanced_positional_args_correctly_excludes_matching_arity
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', ['method/2'])
    end

    temp_file.write(<<~RUBY)
      class Example
        # Documented method
        # @param a [String] first param
        # @param b [String] second param
        def method(a, b)
          [a, b]
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    # Should be excluded from UndocumentedObject check (2 positional params)
    undoc_objects = result.offenses.select { |o| o[:name] == 'UndocumentedObject' }
    refute(undoc_objects.any? { |o| o[:message].match?(/\bmethod\b/) })
  end

  def test_advanced_positional_args_does_not_exclude_different_arity
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', ['method/2'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def method(a, b, c)
          [a, b, c]
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    # Should NOT be excluded (3 params, not 2)
    assert(result.offenses.any? { |o| o[:message].match?(/\bmethod\b/) })
  end

  # --- Advanced: splat and block parameters with arity ---

  def test_advanced_splat_not_counted_in_arity
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', ['method/2'])
    end

    temp_file.write(<<~RUBY)
      class Example
        # Documented method
        # @param a [String] first param
        # @param b [String] second param
        # @param rest [Array] remaining params
        def method(a, b, *rest)
          [a, b, rest]
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    # Should match /2 (not counting *rest)
    undoc_objects = result.offenses.select { |o| o[:name] == 'UndocumentedObject' }
    refute(undoc_objects.any? { |o| o[:message].match?(/\bmethod\b/) })
  end

  def test_advanced_block_not_counted_in_arity
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', ['method/2'])
    end

    temp_file.write(<<~RUBY)
      class Example
        # Documented method
        # @param a [String] first param
        # @param b [String] second param
        # @yield block callback
        def method(a, b, &block)
          [a, b, block]
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    # Should match /2 (not counting &block)
    undoc_objects = result.offenses.select { |o| o[:name] == 'UndocumentedObject' }
    refute(undoc_objects.any? { |o| o[:message].match?(/\bmethod\b/) })
  end

  # --- Advanced: operator methods ---

  def test_advanced_excludes_binary_operators
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', ['+', '-', '==', '===', '<=>', '+@', '-@', '!', '~'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def +(other)
          self
        end

        def -(other)
          self
        end

        def ==(other)
          true
        end

        def <=>(other)
          0
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    operator_pattern = /\+|-|==|<=>|Example#\+|Example#-|Example#==|Example#<=>/
    refute(result.offenses.any? { |o| o[:element]&.match?(operator_pattern) })
  end

  def test_advanced_excludes_unary_operators
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', ['+', '-', '==', '===', '<=>', '+@', '-@', '!', '~'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def +@
          self
        end

        def -@
          self.class.new(-value)
        end

        def !
          false
        end

        def ~
          self
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    refute(result.offenses.any? { |o| o[:element]&.match?(/\+@|-@|!|~/) })
  end

  # --- Advanced: ASCII method names with combined patterns ---

  def test_advanced_ascii_method_names_handled_normally
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', ['to_s', '/^test/'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def to_s
          'example'
        end

        def test_method
          'test'
        end

        def other
          'other'
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    refute(result.offenses.any? { |o| o[:message].match?(/to_s|test_method/) })
    assert(result.offenses.any? { |o| o[:message].match?(/other/) })
  end

  # --- Advanced: complex parameter signatures ---

  def test_advanced_counts_optional_parameters_in_arity
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', ['method/3'])
    end

    temp_file.write(<<~RUBY)
      class Example
        # Documented method
        # @param a [String] required param
        # @param b [String, nil] optional param
        # @param c [String] optional with default
        def method(a, b = nil, c = 'default')
          [a, b, c]
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    # Should count all params including optional (3 total)
    undoc_objects = result.offenses.select { |o| o[:name] == 'UndocumentedObject' }
    refute(undoc_objects.any? { |o| o[:message].match?(/\bmethod\b/) })
  end

  def test_advanced_distinguishes_different_arities
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', ['method/3'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def method(a, b, c, d)
          [a, b, c, d]
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    # 4 params, should NOT match /3
    assert(result.offenses.any? { |o| o[:message].match?(/\bmethod\b/) })
  end

  # --- Advanced: pattern precedence ---

  def test_advanced_pattern_precedence_excludes_when_any_pattern_matches
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
        'ExcludedMethods', ['initialize', 'initialize/0', '/^init/'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def initialize
          @value = 1
        end

        def initialize_db
          'db'
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    # All three patterns match initialize
    # Only regex matches initialize_db
    refute(result.offenses.any? { |o| o[:message].match?(/initialize/) })
  end
end

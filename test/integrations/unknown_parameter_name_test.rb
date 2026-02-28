# frozen_string_literal: true

require 'tempfile'
require 'test_helper'

class UnknownParameterNameIntegrationTest < Minitest::Test
  attr_reader :config, :temp_file

  def setup
    @temp_file = Tempfile.new(['test', '.rb'])
    @config = test_config do |c|
      c.send(:set_validator_config, 'Warnings/UnknownParameterName', 'Enabled', true)
    end
  end

  def teardown
    temp_file.unlink
  end

  def test_when_param_documents_non_existent_parameter_reports_offense
    temp_file.write(<<~RUBY)
      # frozen_string_literal: true

      # Test class for unknown parameters
      class TestClass
        # Method with wrong parameter documentation
        # @param current [String] documented but doesn't exist
        # @return [String] the value
        def method_with_wrong_param(value)
          value
        end
      end
    RUBY
    temp_file.rewind

    result = Yard::Lint.run(path: temp_file.path, progress: false, config: config)
    offense = result.offenses.find { |o| o[:name] == 'UnknownParameterName' }

    refute_nil(offense)
    assert_equal(temp_file.path, offense[:location])
    assert_equal(8, offense[:location_line]) # Line where method is defined
    assert_includes(offense[:message], 'current')
  end

  def test_when_param_documents_splat_parameter_reports_offense_for_dots
    temp_file.write(<<~RUBY)
      # frozen_string_literal: true

      # Test class
      class TestClass
        # Method with splat parameter documentation
        # @param args [Array] the arguments
        # @param ... [Object] additional args (invalid YARD syntax)
        # @return [Array] the arguments
        def method_with_splat(*args)
          args
        end
      end
    RUBY
    temp_file.rewind

    result = Yard::Lint.run(path: temp_file.path, progress: false, config: config)
    offense = result.offenses.find do |o|
      o[:name] == 'UnknownParameterName' && o[:message].include?('...')
    end

    refute_nil(offense)
    assert_equal(temp_file.path, offense[:location])
    assert_equal(9, offense[:location_line]) # Line where method is defined
    assert_includes(offense[:message], '...')
  end

  def test_when_method_has_correct_param_tags_does_not_report_any_offense
    temp_file.write(<<~RUBY)
      # frozen_string_literal: true

      # Test class
      class TestClass
        # Correctly documented method
        # @param value [String] the value
        # @return [String] the value
        def method_with_correct_param(value)
          value
        end
      end
    RUBY
    temp_file.rewind

    result = Yard::Lint.run(path: temp_file.path, progress: false, config: config)
    offenses = result.offenses.select { |o| o[:name] == 'UnknownParameterName' }

    assert_empty(offenses)
  end

  def test_when_documenting_star_args_parameter_reports_offense
    temp_file.write(<<~RUBY)
      # frozen_string_literal: true

      # Test class
      class TestClass
        # Method with invalid *args documentation
        # @param *args [Array] the arguments (invalid syntax)
        # @return [Array] the arguments
        def method_with_splat(*args)
          args
        end
      end
    RUBY
    temp_file.rewind

    result = Yard::Lint.run(path: temp_file.path, progress: false, config: config)
    offense = result.offenses.find do |o|
      o[:name] == 'UnknownParameterName' && o[:message].include?('*args')
    end

    refute_nil(offense)
    assert_equal(temp_file.path, offense[:location])
    assert_equal(8, offense[:location_line]) # Line where method is defined
    assert_includes(offense[:message], '*args')
  end

  def test_location_reporting_reports_all_offenses_with_correct_file_paths
    temp_file.write(<<~RUBY)
      # frozen_string_literal: true

      # Test class with multiple unknown parameters
      class TestClass
        # First method
        # @param wrong1 [String] wrong param
        def first_method(value1)
          value1
        end

        # Second method
        # @param wrong2 [String] wrong param
        def second_method(value2)
          value2
        end

        # Third method
        # @param wrong3 [String] wrong param
        def third_method(value3)
          value3
        end
      end
    RUBY
    temp_file.rewind

    result = Yard::Lint.run(path: temp_file.path, progress: false, config: config)
    offenses = result.offenses.select { |o| o[:name] == 'UnknownParameterName' }

    assert_equal(3, offenses.size)

    # All offenses should have the full file path, not empty or nil
    offenses.each do |offense|
      assert_equal(temp_file.path, offense[:location])
      refute_empty(offense[:location])
      refute_nil(offense[:location])
      assert_operator(offense[:location_line], :>, 0)
    end

    # Verify specific line numbers (where methods are defined)
    assert_equal([7, 13, 19], offenses.map { |o| o[:location_line] }.sort)
  end

  def test_did_you_mean_when_parameter_name_is_a_typo_suggests_the_correct_parameter_name
    temp_file.write(<<~RUBY)
      # frozen_string_literal: true

      # Test class
      class TestClass
        # Method with typo in parameter documentation
        # @param user_nme [String] typo in parameter name
        # @return [String] the user name
        def process(user_name)
          user_name
        end
      end
    RUBY
    temp_file.rewind

    result = Yard::Lint.run(path: temp_file.path, progress: false, config: config)
    offense = result.offenses.find { |o| o[:name] == 'UnknownParameterName' }

    refute_nil(offense)
    assert_includes(offense[:message], 'user_nme')
    assert_includes(offense[:message], "did you mean 'user_name'?")
  end

  def test_did_you_mean_when_parameter_name_changed_during_refactoring_suggests_similar_for_first
    temp_file.write(<<~RUBY)
      # frozen_string_literal: true

      # Test class
      class TestClass
        # Method that was refactored
        # @param old_value [String] old parameter name from before refactoring
        # @param old_count [Integer] another old parameter
        # @return [String] result
        def process(new_value, new_count)
          "\#{new_value}\#{new_count}"
        end
      end
    RUBY
    temp_file.rewind

    result = Yard::Lint.run(path: temp_file.path, progress: false, config: config)
    offenses = result.offenses.select { |o| o[:name] == 'UnknownParameterName' }

    assert_equal(2, offenses.size)

    old_value_offense = offenses.find { |o| o[:message].include?('old_value') }
    assert_includes(old_value_offense[:message], "did you mean 'new_value'?")
  end

  def test_did_you_mean_when_parameter_name_changed_during_refactoring_suggests_similar_for_second
    temp_file.write(<<~RUBY)
      # frozen_string_literal: true

      # Test class
      class TestClass
        # Method that was refactored
        # @param old_value [String] old parameter name from before refactoring
        # @param old_count [Integer] another old parameter
        # @return [String] result
        def process(new_value, new_count)
          "\#{new_value}\#{new_count}"
        end
      end
    RUBY
    temp_file.rewind

    result = Yard::Lint.run(path: temp_file.path, progress: false, config: config)
    offenses = result.offenses.select { |o| o[:name] == 'UnknownParameterName' }

    old_count_offense = offenses.find { |o| o[:message].include?('old_count') }
    assert_includes(old_count_offense[:message], "did you mean 'new_count'?")
  end

  def test_did_you_mean_when_parameter_name_is_completely_different_does_not_suggest
    temp_file.write(<<~RUBY)
      # frozen_string_literal: true

      # Test class
      class TestClass
        # Method with completely different parameter
        # @param xyz [String] completely unrelated name
        # @return [String] the value
        def process(value)
          value
        end
      end
    RUBY
    temp_file.rewind

    result = Yard::Lint.run(path: temp_file.path, progress: false, config: config)
    offense = result.offenses.find { |o| o[:name] == 'UnknownParameterName' }

    refute_nil(offense)
    assert_includes(offense[:message], 'xyz')
    refute_includes(offense[:message], 'did you mean')
  end

  def test_did_you_mean_when_method_has_multiple_parameters_suggests_closest_matching
    temp_file.write(<<~RUBY)
      # frozen_string_literal: true

      # Test class
      class TestClass
        # Method with multiple parameters
        # @param usr [String] typo
        # @param email [String] correct
        # @param age [Integer] correct
        # @return [String] result
        def process(user, email, age)
          "\#{user} \#{email} \#{age}"
        end
      end
    RUBY
    temp_file.rewind

    result = Yard::Lint.run(path: temp_file.path, progress: false, config: config)
    offense = result.offenses.find { |o| o[:name] == 'UnknownParameterName' }

    refute_nil(offense)
    assert_includes(offense[:message], 'usr')
    assert_includes(offense[:message], "did you mean 'user'?")
  end

  def test_did_you_mean_with_keyword_arguments_suggests_correct_keyword_parameter_names
    temp_file.write(<<~RUBY)
      # frozen_string_literal: true

      # Test class
      class TestClass
        # Method with keyword arguments
        # @param nam [String] typo in keyword argument
        # @param emai [String] typo in keyword argument
        # @return [String] result
        def process(name:, email:)
          "\#{name} \#{email}"
        end
      end
    RUBY
    temp_file.rewind

    result = Yard::Lint.run(path: temp_file.path, progress: false, config: config)
    offenses = result.offenses.select { |o| o[:name] == 'UnknownParameterName' }

    assert_equal(2, offenses.size)

    nam_offense = offenses.find { |o| o[:message].include?('nam') }
    assert_includes(nam_offense[:message], "did you mean 'name'?")

    emai_offense = offenses.find { |o| o[:message].include?('emai') }
    assert_includes(emai_offense[:message], "did you mean 'email'?")
  end

  def test_did_you_mean_with_splat_and_block_parameters_suggests_names_without_special_chars
    temp_file.write(<<~RUBY)
      # frozen_string_literal: true

      # Test class
      class TestClass
        # Method with various parameter types
        # @param nam [String] typo
        # @param arg [Array] typo (should be args)
        # @param kwarg [Hash] typo (should be kwargs)
        # @return [String] result
        def process(name, *args, **kwargs, &block)
          name
        end
      end
    RUBY
    temp_file.rewind

    result = Yard::Lint.run(path: temp_file.path, progress: false, config: config)
    offenses = result.offenses.select { |o| o[:name] == 'UnknownParameterName' }

    arg_offense = offenses.find { |o| o[:message].include?('arg') && !o[:message].include?('kwarg') }
    refute_nil(arg_offense)
    assert_includes(arg_offense[:message], "did you mean 'args'?")

    kwarg_offense = offenses.find { |o| o[:message].include?('kwarg') }
    refute_nil(kwarg_offense)
    assert_includes(kwarg_offense[:message], "did you mean 'kwargs'?")
  end
end

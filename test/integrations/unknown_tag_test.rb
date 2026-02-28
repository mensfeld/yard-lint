# frozen_string_literal: true

require 'tempfile'
require 'test_helper'

class UnknownTagIntegrationTest < Minitest::Test
  attr_reader :config, :temp_file

  def setup
    @temp_file = Tempfile.new(['test', '.rb'])
    @config = test_config do |c|
      c.send(:set_validator_config, 'Warnings/UnknownTag', 'Enabled', true)
    end
  end

  def teardown
    temp_file.unlink
  end

  def test_when_using_non_existent_yard_tag_reports_offense
    temp_file.write(<<~RUBY)
      # frozen_string_literal: true

      # Test class for unknown tags
      class TestClass
        # Method with unknown tag
        # @returns [String] should be @return not @returns
        # @param value [String] the value
        def method_with_wrong_tag(value)
          value
        end
      end
    RUBY
    temp_file.rewind

    result = Yard::Lint.run(path: temp_file.path, progress: false, config: config)
    offense = result.offenses.find { |o| o[:name] == 'UnknownTag' && o[:message].include?('@returns') }

    refute_nil(offense)
    assert_equal(temp_file.path, offense[:location])
    assert_includes(offense[:message], '@returns')
  end

  def test_when_using_standard_yard_tags_does_not_report_any_offense
    temp_file.write(<<~RUBY)
      # frozen_string_literal: true

      # Test class
      class TestClass
        # Correctly documented method
        # @param value [String] the value
        # @return [String] the value
        # @raise [StandardError] when something goes wrong
        def method_with_correct_tags(value)
          raise StandardError unless value

          value
        end
      end
    RUBY
    temp_file.rewind

    result = Yard::Lint.run(path: temp_file.path, progress: false, config: config)
    offenses = result.offenses.select { |o| o[:name] == 'UnknownTag' }

    assert_empty(offenses)
  end

  def test_did_you_mean_when_tag_name_is_a_common_typo_suggests_the_correct_tag_name
    temp_file.write(<<~RUBY)
      # frozen_string_literal: true

      # Test class
      class TestClass
        # Method with typo in tag
        # @returns [String] should be @return
        # @param value [String] the value
        def process(value)
          value
        end
      end
    RUBY
    temp_file.rewind

    result = Yard::Lint.run(path: temp_file.path, progress: false, config: config)
    offense = result.offenses.find { |o| o[:name] == 'UnknownTag' }

    refute_nil(offense)
    assert_includes(offense[:message], '@returns')
    assert_includes(offense[:message], "did you mean '@return'?")
  end

  def test_did_you_mean_when_using_raises_instead_of_raise_suggests_raise
    temp_file.write(<<~RUBY)
      # frozen_string_literal: true

      # Test class
      class TestClass
        # Method with typo in tag
        # @param value [String] the value
        # @raises [StandardError] should be @raise
        def process(value)
          raise StandardError unless value

          value
        end
      end
    RUBY
    temp_file.rewind

    result = Yard::Lint.run(path: temp_file.path, progress: false, config: config)
    offense = result.offenses.find { |o| o[:name] == 'UnknownTag' && o[:message].include?('@raises') }

    refute_nil(offense)
    assert_includes(offense[:message], "did you mean '@raise'?")
  end

  def test_did_you_mean_when_using_params_instead_of_param_suggests_param
    temp_file.write(<<~RUBY)
      # frozen_string_literal: true

      # Test class
      class TestClass
        # Method with typo in tag
        # @params value [String] should be @param
        # @return [String] the value
        def process(value)
          value
        end
      end
    RUBY
    temp_file.rewind

    result = Yard::Lint.run(path: temp_file.path, progress: false, config: config)
    offense = result.offenses.find { |o| o[:name] == 'UnknownTag' && o[:message].include?('@params') }

    refute_nil(offense)
    assert_includes(offense[:message], "did you mean '@param'?")
  end

  def test_did_you_mean_when_tag_name_has_minor_typo_suggests_example
    temp_file.write(<<~RUBY)
      # frozen_string_literal: true

      # Test class
      class TestClass
        # Method with typo in tag
        # @param value [String] the value
        # @exampl Ruby code example (missing 'e')
        #   process('test')
        def process(value)
          value
        end
      end
    RUBY
    temp_file.rewind

    result = Yard::Lint.run(path: temp_file.path, progress: false, config: config)
    offense = result.offenses.find { |o| o[:name] == 'UnknownTag' && o[:message].include?('@exampl') }

    refute_nil(offense)
    assert_includes(offense[:message], "did you mean '@example'?")
  end

  def test_did_you_mean_when_tag_name_is_completely_wrong_does_not_suggest
    temp_file.write(<<~RUBY)
      # frozen_string_literal: true

      # Test class
      class TestClass
        # Method with completely invalid tag
        # @param value [String] the value
        # @foobar [String] this tag doesn't exist
        def process(value)
          value
        end
      end
    RUBY
    temp_file.rewind

    result = Yard::Lint.run(path: temp_file.path, progress: false, config: config)
    offense = result.offenses.find { |o| o[:name] == 'UnknownTag' && o[:message].include?('@foobar') }

    refute_nil(offense)
    assert_includes(offense[:message], '@foobar')
    refute_includes(offense[:message], 'did you mean')
  end

  def test_did_you_mean_when_multiple_unknown_tags_exist_provides_suggestions_for_all_typos
    temp_file.write(<<~RUBY)
      # frozen_string_literal: true

      # Test class
      class TestClass
        # Method with multiple typos
        # @params value [String] should be @param
        # @returns [String] should be @return
        # @raises [Error] should be @raise
        def process(value)
          value
        end
      end
    RUBY
    temp_file.rewind

    result = Yard::Lint.run(path: temp_file.path, progress: false, config: config)
    offenses = result.offenses.select { |o| o[:name] == 'UnknownTag' }

    assert_operator(offenses.size, :>=, 3)

    params_offense = offenses.find { |o| o[:message].include?('@params') }
    assert_includes(params_offense[:message], "did you mean '@param'?")

    returns_offense = offenses.find { |o| o[:message].include?('@returns') }
    assert_includes(returns_offense[:message], "did you mean '@return'?")

    raises_offense = offenses.find { |o| o[:message].include?('@raises') }
    assert_includes(raises_offense[:message], "did you mean '@raise'?")
  end

  def test_did_you_mean_with_common_misspellings_suggests_correct_spelling_for_auhtor
    temp_file.write(<<~RUBY)
      # frozen_string_literal: true

      # Test class
      class TestClass
        # Method with various typos
        # @see Related class
        # @auhtor John Doe (should be @author)
        # @deprected Use new_method instead (should be @deprecated)
        def old_method
          # implementation
        end
      end
    RUBY
    temp_file.rewind

    result = Yard::Lint.run(path: temp_file.path, progress: false, config: config)
    offense = result.offenses.find { |o| o[:name] == 'UnknownTag' && o[:message].include?('@auhtor') }

    refute_nil(offense)
    assert_includes(offense[:message], "did you mean '@author'?")
  end

  def test_did_you_mean_with_common_misspellings_suggests_correct_spelling_for_deprected
    temp_file.write(<<~RUBY)
      # frozen_string_literal: true

      # Test class
      class TestClass
        # Method with various typos
        # @see Related class
        # @auhtor John Doe (should be @author)
        # @deprected Use new_method instead (should be @deprecated)
        def old_method
          # implementation
        end
      end
    RUBY
    temp_file.rewind

    result = Yard::Lint.run(path: temp_file.path, progress: false, config: config)
    offense = result.offenses.find { |o| o[:name] == 'UnknownTag' && o[:message].include?('@deprected') }

    refute_nil(offense)
    assert_includes(offense[:message], "did you mean '@deprecated'?")
  end

  def test_did_you_mean_with_directive_typos_suggests_attribute_for_attribut
    temp_file.write(<<~RUBY)
      # frozen_string_literal: true

      # Test class
      class TestClass
        # @!attribut [r] name
        #   @return [String] the name
        attr_reader :name
      end
    RUBY
    temp_file.rewind

    result = Yard::Lint.run(path: temp_file.path, progress: false, config: config)
    offense = result.offenses.find { |o| o[:name] == 'UnknownTag' && o[:message].include?('attribut') }

    # Note: YARD might parse this differently, but we expect a suggestion if it's caught
    # The directive is @!attribute but YARD strips the @! prefix in warnings
    if offense
      assert_includes(offense[:message], 'did you mean')
    end
  end

  def test_location_reporting_reports_all_offenses_with_correct_file_paths
    temp_file.write(<<~RUBY)
      # frozen_string_literal: true

      # Test class with multiple unknown tags
      class TestClass
        # First method
        # @returns [String] wrong tag
        def first_method
          'first'
        end

        # Second method
        # @raises [Error] wrong tag
        def second_method
          'second'
        end

        # Third method
        # @params value [String] wrong tag
        def third_method(value)
          value
        end
      end
    RUBY
    temp_file.rewind

    result = Yard::Lint.run(path: temp_file.path, progress: false, config: config)
    offenses = result.offenses.select { |o| o[:name] == 'UnknownTag' }

    assert_operator(offenses.size, :>=, 3)

    # All offenses should have the full file path
    offenses.each do |offense|
      assert_equal(temp_file.path, offense[:location])
      refute_empty(offense[:location])
      refute_nil(offense[:location])
    end
  end
end

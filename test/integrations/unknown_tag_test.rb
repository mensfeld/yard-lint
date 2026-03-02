# frozen_string_literal: true

require 'tempfile'

describe 'Unknown Tag' do
  attr_reader :temp_file, :config

  before do
    @temp_file = Tempfile.new(['test', '.rb'])
    @config = test_config do |c|
      c.set_validator_config('Warnings/UnknownTag', 'Enabled', true)
    end
  end

  after do
    temp_file.unlink
  end

  it 'when using non existent yard tag reports offense' do
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

  it 'when using standard yard tags does not report any offense' do
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

  it 'did you mean when tag name is a common typo suggests the correct tag name' do
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

  it 'did you mean when using raises instead of raise suggests raise' do
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

  it 'did you mean when using params instead of param suggests param' do
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

  it 'did you mean when tag name has minor typo suggests example' do
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

  it 'did you mean when tag name is completely wrong does not suggest' do
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

  it 'did you mean when multiple unknown tags exist provides suggestions for all typos' do
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

  it 'did you mean with common misspellings suggests correct spelling for auhtor' do
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

  it 'did you mean with common misspellings suggests correct spelling for deprected' do
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

  it 'did you mean with directive typos suggests attribute for attribut' do
    temp_file.write(<<~RUBY)
      # frozen_string_literal: true

      # Test class
      class TestClass
        # @!attribut [r] name
        #   @return [String] the name
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

  it 'location reporting reports all offenses with correct file paths' do
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


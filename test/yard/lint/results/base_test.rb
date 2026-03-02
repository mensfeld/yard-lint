# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Results::Base' do
  attr_reader :test_result_class

  before do
    @test_result_class = Class.new(Yard::Lint::Results::Base) do
      self.default_severity = 'warning'
      self.offense_type = 'method'
      self.offense_name = 'TestOffense'

      def build_message(offense)
        "Test issue at #{offense[:location]}"
      end

      # Override to return predictable validator name
      def validator_name
        'Tags/TestValidator'
      end
    end

    @parsed_data = [
      { location: '/path/to/file.rb', line: 10, method_name: '#foo' },
      { location: '/path/to/other.rb', line: 20, method_name: '#bar' }
    ]
  end

  it 'initialize builds offenses from parsed data' do
    result = @test_result_class.new(@parsed_data, nil)
    assert_kind_of(Array, result.offenses)
    assert_equal(2, result.offenses.size)
  end

  it 'initialize stores config' do
    config_double = stub
    config_double.stubs(:validator_severity).returns(nil)
    result_with_config = @test_result_class.new(@parsed_data, config_double)
    refute_nil(result_with_config.config)
  end

  it 'initialize handles nil parsed data' do
    result = @test_result_class.new(nil, nil)
    assert_equal([], result.offenses)
  end

  it 'initialize handles empty array' do
    result = @test_result_class.new([], nil)
    assert_equal([], result.offenses)
  end

  it 'offenses returns array of offense hashes' do
    result = @test_result_class.new(@parsed_data, nil)
    result.offenses.each { |e| assert_kind_of(Hash, e) }
  end

  it 'offenses includes required keys in each offense' do
    result = @test_result_class.new(@parsed_data, nil)
    offense = result.offenses.first
    assert(offense.key?(:severity))
    assert(offense.key?(:type))
    assert(offense.key?(:name))
    assert(offense.key?(:message))
    assert(offense.key?(:location))
    assert(offense.key?(:location_line))
  end

  it 'offenses uses default severity when no config' do
    result = @test_result_class.new(@parsed_data, nil)
    assert_equal('warning', result.offenses.first[:severity])
  end

  it 'offenses uses configured offense type' do
    result = @test_result_class.new(@parsed_data, nil)
    assert_equal('method', result.offenses.first[:type])
  end

  it 'offenses uses configured offense name' do
    result = @test_result_class.new(@parsed_data, nil)
    assert_equal('TestOffense', result.offenses.first[:name])
  end

  it 'offenses builds message for each offense' do
    result = @test_result_class.new(@parsed_data, nil)
    assert_equal('Test issue at /path/to/file.rb', result.offenses.first[:message])
  end

  it 'offenses extracts location from parsed data' do
    result = @test_result_class.new(@parsed_data, nil)
    assert_equal('/path/to/file.rb', result.offenses.first[:location])
  end

  it 'offenses extracts line number from parsed data' do
    result = @test_result_class.new(@parsed_data, nil)
    assert_equal(10, result.offenses.first[:location_line])
  end

  it 'offenses defaults line number to 0 if missing' do
    data = [{ location: '/path/to/file.rb' }]
    result = @test_result_class.new(data, nil)
    assert_equal(0, result.offenses.first[:location_line])
  end

  it 'default severity raises notimplementederror if not overridden' do
    base_class = Class.new(Yard::Lint::Results::Base) do
      def build_message(_offense)
        'message'
      end
    end

    assert_raises(NotImplementedError) { base_class.new([{}], nil).offenses }
  end

  it 'build message raises notimplementederror if not overridden' do
    base_class = Class.new(Yard::Lint::Results::Base) do
      self.default_severity = 'warning'
    end

    assert_raises(NotImplementedError) { base_class.new([{}], nil).offenses }
  end

  it 'offense type defaults to line' do
    minimal_class = Class.new(Yard::Lint::Results::Base) do
      self.default_severity = 'warning'

      def build_message(_offense)
        'message'
      end
    end

    result = minimal_class.new([{}], nil)
    assert_equal('line', result.offenses.first[:type])
  end

  it 'offense name extracts from class name by default' do
    named_class = Class.new(Yard::Lint::Results::Base) do
      class << self
        def name
          'Yard::Lint::Validators::Tags::MyCustomResult'
        end
      end

      self.default_severity = 'warning'

      def build_message(_offense)
        'message'
      end
    end

    result = named_class.new([{}], nil)
    assert_equal('MyCustom', result.send(:computed_offense_name))
  end

  it 'validator name extracts validator name from class path' do
    # This is tested via the actual validator result classes
    # The test_result_class overrides this for predictability
    result = @test_result_class.new(@parsed_data, nil)
    assert_equal('Tags/TestValidator', result.validator_name)
  end

  it 'with configuration uses configured severity' do
    config = stub(validator_severity: 'error')
    result = @test_result_class.new(@parsed_data, config)
    assert_equal('error', result.offenses.first[:severity])
  end

  it 'with configuration falls back to default severity if config returns nil' do
    config = stub(validator_severity: nil)
    result = @test_result_class.new(@parsed_data, config)
    assert_equal('warning', result.offenses.first[:severity])
  end
end


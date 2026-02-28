# frozen_string_literal: true

require 'test_helper'

class YardLintResultsBaseTest < Minitest::Test
  attr_reader :test_result_class, :parsed_data

  def setup
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

  def test_initialize_builds_offenses_from_parsed_data
    result = @test_result_class.new(@parsed_data, nil)
    assert_kind_of(Array, result.offenses)
    assert_equal(2, result.offenses.size)
  end

  def test_initialize_stores_config
    config_double = stub
    config_double.stubs(:validator_severity).returns(nil)
    result_with_config = @test_result_class.new(@parsed_data, config_double)
    refute_nil(result_with_config.config)
  end

  def test_initialize_handles_nil_parsed_data
    result = @test_result_class.new(nil, nil)
    assert_equal([], result.offenses)
  end

  def test_initialize_handles_empty_array
    result = @test_result_class.new([], nil)
    assert_equal([], result.offenses)
  end

  def test_offenses_returns_array_of_offense_hashes
    result = @test_result_class.new(@parsed_data, nil)
    result.offenses.each { |e| assert_kind_of(Hash, e) }
  end

  def test_offenses_includes_required_keys_in_each_offense
    result = @test_result_class.new(@parsed_data, nil)
    offense = result.offenses.first
    assert(offense.key?(:severity))
    assert(offense.key?(:type))
    assert(offense.key?(:name))
    assert(offense.key?(:message))
    assert(offense.key?(:location))
    assert(offense.key?(:location_line))
  end

  def test_offenses_uses_default_severity_when_no_config
    result = @test_result_class.new(@parsed_data, nil)
    assert_equal('warning', result.offenses.first[:severity])
  end

  def test_offenses_uses_configured_offense_type
    result = @test_result_class.new(@parsed_data, nil)
    assert_equal('method', result.offenses.first[:type])
  end

  def test_offenses_uses_configured_offense_name
    result = @test_result_class.new(@parsed_data, nil)
    assert_equal('TestOffense', result.offenses.first[:name])
  end

  def test_offenses_builds_message_for_each_offense
    result = @test_result_class.new(@parsed_data, nil)
    assert_equal('Test issue at /path/to/file.rb', result.offenses.first[:message])
  end

  def test_offenses_extracts_location_from_parsed_data
    result = @test_result_class.new(@parsed_data, nil)
    assert_equal('/path/to/file.rb', result.offenses.first[:location])
  end

  def test_offenses_extracts_line_number_from_parsed_data
    result = @test_result_class.new(@parsed_data, nil)
    assert_equal(10, result.offenses.first[:location_line])
  end

  def test_offenses_defaults_line_number_to_0_if_missing
    data = [{ location: '/path/to/file.rb' }]
    result = @test_result_class.new(data, nil)
    assert_equal(0, result.offenses.first[:location_line])
  end

  def test_default_severity_raises_notimplementederror_if_not_overridden
    base_class = Class.new(Yard::Lint::Results::Base) do
      def build_message(_offense)
        'message'
      end
    end

    assert_raises(NotImplementedError) { base_class.new([{}], nil).offenses }
  end

  def test_build_message_raises_notimplementederror_if_not_overridden
    base_class = Class.new(Yard::Lint::Results::Base) do
      self.default_severity = 'warning'
    end

    assert_raises(NotImplementedError) { base_class.new([{}], nil).offenses }
  end

  def test_offense_type_defaults_to_line
    minimal_class = Class.new(Yard::Lint::Results::Base) do
      self.default_severity = 'warning'

      def build_message(_offense)
        'message'
      end
    end

    result = minimal_class.new([{}], nil)
    assert_equal('line', result.offenses.first[:type])
  end

  def test_offense_name_extracts_from_class_name_by_default
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

  def test_validator_name_extracts_validator_name_from_class_path
    # This is tested via the actual validator result classes
    # The test_result_class overrides this for predictability
    result = @test_result_class.new(@parsed_data, nil)
    assert_equal('Tags/TestValidator', result.validator_name)
  end

  def test_with_configuration_uses_configured_severity
    config = stub(validator_severity: 'error')
    result = @test_result_class.new(@parsed_data, config)
    assert_equal('error', result.offenses.first[:severity])
  end

  def test_with_configuration_falls_back_to_default_severity_if_config_returns_nil
    config = stub(validator_severity: nil)
    result = @test_result_class.new(@parsed_data, config)
    assert_equal('warning', result.offenses.first[:severity])
  end
end

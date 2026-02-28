# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsBaseInitializeTest < Minitest::Test
  attr_reader :config, :selection, :validator

  def setup
    @config = Yard::Lint::Config.new
    @selection = ['lib/example.rb']
    @validator = Yard::Lint::Validators::Base.new(config, selection)
  end

  def test_initialize_stores_config
    assert_equal(config, validator.config)
  end

  def test_initialize_stores_selection
    assert_equal(selection, validator.selection)
  end
end

class YardLintValidatorsBaseInProcessTest < Minitest::Test
  attr_reader :validator_class

  def setup
    @validator_class = Class.new(Yard::Lint::Validators::Base) do
      in_process visibility: :all
    end
  end

  def test_in_process_marks_the_validator_as_in_process_enabled
    assert_equal(true, validator_class.in_process?)
  end

  def test_in_process_stores_the_visibility_setting
    assert_equal(:all, validator_class.in_process_visibility)
  end

  def test_in_process_returns_false_by_default
    assert_equal(false, Yard::Lint::Validators::Base.in_process?)
  end
end

class YardLintValidatorsBaseValidatorNameTest < Minitest::Test
  def test_validator_name_returns_nil_for_base_class
    assert_nil(Yard::Lint::Validators::Base.validator_name)
  end

  def test_validator_name_extracts_name_from_valid_namespace
    named_class = Class.new(Yard::Lint::Validators::Base) do
      def self.name
        'Yard::Lint::Validators::Tags::Order::Validator'
      end
    end
    assert_equal('Tags/Order', named_class.validator_name)
  end
end

class YardLintValidatorsBaseInProcessQueryTest < Minitest::Test
  attr_reader :validator

  def setup
    @config = Yard::Lint::Config.new
    @selection = ['lib/example.rb']
    @validator = Yard::Lint::Validators::Base.new(@config, @selection)
  end

  def test_in_process_query_raises_notimplementederror_by_default
    object = stub
    collector = stub
    assert_raises(NotImplementedError) { validator.in_process_query(object, collector) }
  end
end

class YardLintValidatorsBaseConfigOrDefaultTest < Minitest::Test
  attr_reader :config, :selection, :validator

  def setup
    @config = Yard::Lint::Config.new
    @selection = ['lib/example.rb']

    concrete_validator_class = Class.new(Yard::Lint::Validators::Base) do
      def self.name
        'Yard::Lint::Validators::Tags::TestValidator::Validator'
      end
    end

    @validator = concrete_validator_class.new(config, selection)
  end

  def test_config_or_default_when_config_value_exists_returns_the_configured_value
    config.stubs(:validator_config)
      .with('Tags/TestValidator', 'SomeKey')
      .returns('configured_value')

    result = validator.send(:config_or_default, 'SomeKey')
    assert_equal('configured_value', result)
  end

  def test_config_or_default_when_config_value_is_nil_returns_the_default_value
    config.stubs(:validator_config)
      .with('Tags/TestValidator', 'SomeKey')
      .returns(nil)

    # Define the Config class in the expected namespace
    # We need to create the module hierarchy for the test
    unless defined?(Yard::Lint::Validators::Tags::TestValidator)
      Yard::Lint::Validators::Tags.const_set(:TestValidator, Module.new)
    end

    config_class = Class.new do
      def self.defaults
        { 'SomeKey' => 'default_value' }
      end
    end

    Yard::Lint::Validators::Tags::TestValidator.const_set(:Config, config_class)

    result = validator.send(:config_or_default, 'SomeKey')
    assert_equal('default_value', result)
  ensure
    if defined?(Yard::Lint::Validators::Tags::TestValidator::Config)
      Yard::Lint::Validators::Tags::TestValidator.send(:remove_const, :Config)
    end
    if defined?(Yard::Lint::Validators::Tags::TestValidator)
      Yard::Lint::Validators::Tags.send(:remove_const, :TestValidator)
    end
  end

  def test_config_or_default_when_validator_name_cannot_be_extracted_returns_nil
    invalid_validator_class = Class.new(Yard::Lint::Validators::Base) do
      def self.name
        'InvalidClassName'
      end
    end

    invalid_validator = invalid_validator_class.new(config, selection)
    result = invalid_validator.send(:config_or_default, 'SomeKey')
    assert_nil(result)
  end
end

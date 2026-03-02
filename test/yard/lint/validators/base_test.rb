# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Validators::Base' do
  attr_reader :config, :selection, :validator

  before do
    @config = Yard::Lint::Config.new
    @selection = ['lib/example.rb']
    @validator = Yard::Lint::Validators::Base.new(config, selection)
  end

  it 'initialize stores config' do
    assert_equal(config, validator.config)
  end

  it 'initialize stores selection' do
    assert_equal(selection, validator.selection)
  end
end

describe 'YardLintValidatorsBaseInProcess' do
  attr_reader :validator_class

  before do
    @validator_class = Class.new(Yard::Lint::Validators::Base) do
      in_process visibility: :all
    end
  end

  it 'in process marks the validator as in process enabled' do
    assert_equal(true, validator_class.in_process?)
  end

  it 'in process stores the visibility setting' do
    assert_equal(:all, validator_class.in_process_visibility)
  end

  it 'in process returns false by default' do
    assert_equal(false, Yard::Lint::Validators::Base.in_process?)
  end
end

describe 'YardLintValidatorsBaseValidatorName' do
  it 'validator name returns nil for base class' do
    assert_nil(Yard::Lint::Validators::Base.validator_name)
  end

  it 'validator name extracts name from valid namespace' do
    named_class = Class.new(Yard::Lint::Validators::Base) do
      def self.name
        'Yard::Lint::Validators::Tags::Order::Validator'
      end
    end
    assert_equal('Tags/Order', named_class.validator_name)
  end
end

describe 'YardLintValidatorsBaseInProcessQuery' do
  attr_reader :config, :selection, :validator

  before do
    @config = Yard::Lint::Config.new
    @selection = ['lib/example.rb']
    @validator = Yard::Lint::Validators::Base.new(@config, @selection)
  end

  it 'in process query raises notimplementederror by default' do
    object = stub
    collector = stub
    assert_raises(NotImplementedError) { validator.in_process_query(object, collector) }
  end
end

describe 'YardLintValidatorsBaseConfigOrDefault' do
  attr_reader :config, :selection, :validator

  before do
    @config = Yard::Lint::Config.new
    @selection = ['lib/example.rb']

    concrete_validator_class = Class.new(Yard::Lint::Validators::Base) do
      def self.name
        'Yard::Lint::Validators::Tags::TestValidator::Validator'
      end
    end

    @validator = concrete_validator_class.new(config, selection)
  end

  it 'config or default when config value exists returns the configured value' do
    config.stubs(:validator_config)
      .with('Tags/TestValidator', 'SomeKey')
      .returns('configured_value')

    result = validator.send(:config_or_default, 'SomeKey')
    assert_equal('configured_value', result)
  end

  it 'config or default when config value is nil returns the default value' do
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

  it 'config or default when validator name cannot be extracted returns nil' do
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


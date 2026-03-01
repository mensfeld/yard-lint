# frozen_string_literal: true

require 'test_helper'


describe 'Yard::Lint::Validators::Config' do
  attr_reader :test_config_class


  before do
    @test_config_class = Class.new(Yard::Lint::Validators::Config) do
      self.id = :test_validator
      self.defaults = { 'Enabled' => true, 'Severity' => 'warning' }.freeze
    end
  end

  it 'class attributes id allows setting and getting validator identifier' do
    assert_equal(:test_validator, test_config_class.id)
  end

  it 'class attributes id is accessible as class attribute' do
    assert_respond_to(test_config_class, :id)
    assert_respond_to(test_config_class, :id=)
  end

  it 'class attributes defaults allows setting and getting default configuration' do
    assert_equal(
      { 'Enabled' => true, 'Severity' => 'warning' },
      test_config_class.defaults
    )
  end

  it 'class attributes defaults is accessible as class attribute' do
    assert_respond_to(test_config_class, :defaults)
    assert_respond_to(test_config_class, :defaults=)
  end

  it 'class attributes combines with returns empty array by default' do
    assert_equal([], test_config_class.combines_with)
  end

  it 'class attributes combines with allows setting validators to combine with' do
    test_config_class.combines_with = ['Other/Validator']
    assert_equal(['Other/Validator'], test_config_class.combines_with)
  end

  it 'class attributes combines with is accessible as class method' do
    assert_respond_to(test_config_class, :combines_with)
    assert_respond_to(test_config_class, :combines_with=)
  end

  it 'class attributes combines with memoizes empty array on first access' do
    config_class = Class.new(Yard::Lint::Validators::Config)
    first_call = config_class.combines_with
    second_call = config_class.combines_with
    assert_same(first_call, second_call)
  end

  it 'inheritance can be subclassed' do
    subclass = Class.new(Yard::Lint::Validators::Config)
    assert_equal(Yard::Lint::Validators::Config, subclass.superclass)
  end

  it 'inheritance allows each subclass to have independent configuration' do
    config_a = Class.new(Yard::Lint::Validators::Config) do
      self.id = :validator_a
      self.defaults = { 'A' => true }.freeze
    end

    config_b = Class.new(Yard::Lint::Validators::Config) do
      self.id = :validator_b
      self.defaults = { 'B' => false }.freeze
    end

    assert_equal(:validator_a, config_a.id)
    assert_equal(:validator_b, config_b.id)
    assert_equal({ 'A' => true }, config_a.defaults)
    assert_equal({ 'B' => false }, config_b.defaults)
  end
end

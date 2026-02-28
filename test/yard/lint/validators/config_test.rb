# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsConfigTest < Minitest::Test
  attr_reader :test_config_class

  def setup
    @test_config_class = Class.new(Yard::Lint::Validators::Config) do
      self.id = :test_validator
      self.defaults = { 'Enabled' => true, 'Severity' => 'warning' }.freeze
    end
  end

  def test_class_attributes_id_allows_setting_and_getting_validator_identifier
    assert_equal(:test_validator, test_config_class.id)
  end

  def test_class_attributes_id_is_accessible_as_class_attribute
    assert_respond_to(test_config_class, :id)
    assert_respond_to(test_config_class, :id=)
  end

  def test_class_attributes_defaults_allows_setting_and_getting_default_configuration
    assert_equal(
      { 'Enabled' => true, 'Severity' => 'warning' },
      test_config_class.defaults
    )
  end

  def test_class_attributes_defaults_is_accessible_as_class_attribute
    assert_respond_to(test_config_class, :defaults)
    assert_respond_to(test_config_class, :defaults=)
  end

  def test_class_attributes_combines_with_returns_empty_array_by_default
    assert_equal([], test_config_class.combines_with)
  end

  def test_class_attributes_combines_with_allows_setting_validators_to_combine_with
    test_config_class.combines_with = ['Other/Validator']
    assert_equal(['Other/Validator'], test_config_class.combines_with)
  end

  def test_class_attributes_combines_with_is_accessible_as_class_method
    assert_respond_to(test_config_class, :combines_with)
    assert_respond_to(test_config_class, :combines_with=)
  end

  def test_class_attributes_combines_with_memoizes_empty_array_on_first_access
    config_class = Class.new(Yard::Lint::Validators::Config)
    first_call = config_class.combines_with
    second_call = config_class.combines_with
    assert_same(first_call, second_call)
  end

  def test_inheritance_can_be_subclassed
    subclass = Class.new(Yard::Lint::Validators::Config)
    assert_equal(Yard::Lint::Validators::Config, subclass.superclass)
  end

  def test_inheritance_allows_each_subclass_to_have_independent_configuration
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

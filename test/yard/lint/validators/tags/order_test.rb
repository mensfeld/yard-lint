# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsOrderTest < Minitest::Test

  def test_module_structure_is_defined_as_a_module
    assert_kind_of(Module, Yard::Lint::Validators::Tags::Order)
  end

  def test_module_structure_has_config_class
    assert_equal(true, Yard::Lint::Validators::Tags::Order.const_defined?(:Config))
  end

  def test_module_structure_has_validator_class
    assert_equal(true, Yard::Lint::Validators::Tags::Order.const_defined?(:Validator))
  end

  def test_module_structure_has_parser_class
    assert_equal(true, Yard::Lint::Validators::Tags::Order.const_defined?(:Parser))
  end

  def test_module_structure_has_result_class
    assert_equal(true, Yard::Lint::Validators::Tags::Order.const_defined?(:Result))
  end
end


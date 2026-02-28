# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsExampleStyleTest < Minitest::Test

  def test_module_structure_is_defined_as_a_module
    assert_kind_of(Module, Yard::Lint::Validators::Tags::ExampleStyle)
  end

  def test_module_structure_has_config_class
    assert_equal(true, Yard::Lint::Validators::Tags::ExampleStyle.const_defined?(:Config))
  end

  def test_module_structure_has_validator_class
    assert_equal(true, Yard::Lint::Validators::Tags::ExampleStyle.const_defined?(:Validator))
  end

  def test_module_structure_has_parser_class
    assert_equal(true, Yard::Lint::Validators::Tags::ExampleStyle.const_defined?(:Parser))
  end

  def test_module_structure_has_result_class
    assert_equal(true, Yard::Lint::Validators::Tags::ExampleStyle.const_defined?(:Result))
  end

  def test_module_structure_has_messagesbuilder_class
    assert_equal(true, Yard::Lint::Validators::Tags::ExampleStyle.const_defined?(:MessagesBuilder))
  end

  def test_module_structure_has_linterdetector_class
    assert_equal(true, Yard::Lint::Validators::Tags::ExampleStyle.const_defined?(:LinterDetector))
  end

  def test_module_structure_has_rubocoprunner_class
    assert_equal(true, Yard::Lint::Validators::Tags::ExampleStyle.const_defined?(:RubocopRunner))
  end
end


# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsDocumentationBlankLineBeforeDefinitionTest < Minitest::Test

  def test_is_a_module
  assert_kind_of(Module, Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition)
  end

  def test_has_required_sub_modules_and_classes
  assert_equal(true, Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition.const_defined?(:Config))
  assert_equal(true, Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition.const_defined?(:Validator))
  assert_equal(true, Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition.const_defined?(:Parser))
  assert_equal(true, Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition.const_defined?(:Result))
  assert_equal(true, Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition.const_defined?(:MessagesBuilder))
  end
end


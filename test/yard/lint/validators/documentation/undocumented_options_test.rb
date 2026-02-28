# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsDocumentationUndocumentedOptionsTest < Minitest::Test

  def test_is_a_module
  assert_kind_of(Module, Yard::Lint::Validators::Documentation::UndocumentedOptions)
  end

  def test_has_required_sub_modules_and_classes
  assert_equal(true, Yard::Lint::Validators::Documentation::UndocumentedOptions.const_defined?(:Config))
  assert_equal(true, Yard::Lint::Validators::Documentation::UndocumentedOptions.const_defined?(:Validator))
  assert_equal(true, Yard::Lint::Validators::Documentation::UndocumentedOptions.const_defined?(:Parser))
  assert_equal(true, Yard::Lint::Validators::Documentation::UndocumentedOptions.const_defined?(:Result))
  end
end


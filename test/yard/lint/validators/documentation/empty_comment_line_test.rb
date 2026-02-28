# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsDocumentationEmptyCommentLineTest < Minitest::Test

  def test_is_a_module
  assert_kind_of(Module, Yard::Lint::Validators::Documentation::EmptyCommentLine)
  end

  def test_has_required_sub_modules_and_classes
  assert_equal(true, Yard::Lint::Validators::Documentation::EmptyCommentLine.const_defined?(:Config))
  assert_equal(true, Yard::Lint::Validators::Documentation::EmptyCommentLine.const_defined?(:Validator))
  assert_equal(true, Yard::Lint::Validators::Documentation::EmptyCommentLine.const_defined?(:Parser))
  assert_equal(true, Yard::Lint::Validators::Documentation::EmptyCommentLine.const_defined?(:Result))
  assert_equal(true, Yard::Lint::Validators::Documentation::EmptyCommentLine.const_defined?(:MessagesBuilder))
  end
end


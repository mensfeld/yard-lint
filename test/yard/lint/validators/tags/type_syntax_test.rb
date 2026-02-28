# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsTypeSyntaxTest < Minitest::Test

  def test_is_a_module
  assert_kind_of(Module, Yard::Lint::Validators::Tags::TypeSyntax)
  end

  def test_is_defined_under_tags_namespace
  end
end


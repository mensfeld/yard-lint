# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsNonAsciiTypeResultTest < Minitest::Test

  def test_class_attributes_has_default_severity_set_to_warning
    assert_equal('warning', Yard::Lint::Validators::Tags::NonAsciiType::Result.default_severity)
  end

  def test_class_attributes_has_offense_type_set_to_method
    assert_equal('method', Yard::Lint::Validators::Tags::NonAsciiType::Result.offense_type)
  end

  def test_class_attributes_has_offense_name_set_to_nonasciitype
    assert_equal('NonAsciiType', Yard::Lint::Validators::Tags::NonAsciiType::Result.offense_name)
  end

  def test_build_message_delegates_to_messagesbuilder
    offense = {
      tag_name: 'param',
      type_string: 'Symbol, …',
      character: '…',
      codepoint: 'U+2026'
    }

    Yard::Lint::Validators::Tags::NonAsciiType::MessagesBuilder
      .stubs(:call)
      .with(offense)
      .returns('formatted message')

    result = Yard::Lint::Validators::Tags::NonAsciiType::Result.new([])
    message = result.build_message(offense)

    assert_equal('formatted message', message)
  end

  def test_inheritance_inherits_from_results_base
    assert_equal(Yard::Lint::Results::Base, Yard::Lint::Validators::Tags::NonAsciiType::Result.superclass)
  end
end

# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsTagTypePositionResultTest < Minitest::Test
  def test_has_default_severity_set_to_convention
    assert_equal('convention', Yard::Lint::Validators::Tags::TagTypePosition::Result.default_severity)
  end

  def test_has_offense_type_set_to_style
    assert_equal('style', Yard::Lint::Validators::Tags::TagTypePosition::Result.offense_type)
  end

  def test_has_offense_name_set_to_tagtypeposition
    assert_equal('TagTypePosition', Yard::Lint::Validators::Tags::TagTypePosition::Result.offense_name)
  end

  def test_build_message_delegates_to_messagesbuilder
    offense = {
      tag_name: 'param',
      param_name: 'name',
      type_info: 'String',
      detected_style: 'type_after_name'
    }

    Yard::Lint::Validators::Tags::TagTypePosition::MessagesBuilder
      .expects(:call)
      .with(offense)
      .returns('formatted message')

    result = Yard::Lint::Validators::Tags::TagTypePosition::Result.new([])
    message = result.build_message(offense)

    assert_equal('formatted message', message)
  end

  def test_inherits_from_results_base
    assert_equal(Yard::Lint::Results::Base, Yard::Lint::Validators::Tags::TagTypePosition::Result.superclass)
  end
end

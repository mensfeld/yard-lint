# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsForbiddenTagsResultTest < Minitest::Test

  def test_class_attributes_has_default_severity_set_to_convention
    assert_equal('convention', Yard::Lint::Validators::Tags::ForbiddenTags::Result.default_severity)
  end

  def test_class_attributes_has_offense_type_set_to_tag
    assert_equal('tag', Yard::Lint::Validators::Tags::ForbiddenTags::Result.offense_type)
  end

  def test_class_attributes_has_offense_name_set_to_forbiddentags
    assert_equal('ForbiddenTags', Yard::Lint::Validators::Tags::ForbiddenTags::Result.offense_name)
  end

  def test_build_message_delegates_to_messagesbuilder
    offense = {
      tag_name: 'return',
      types_text: 'void',
      pattern_types: 'void'
    }

    Yard::Lint::Validators::Tags::ForbiddenTags::MessagesBuilder
      .stubs(:call)
      .with(offense)
      .returns('formatted message')

    result = Yard::Lint::Validators::Tags::ForbiddenTags::Result.new([])
    message = result.send(:build_message, offense)

    assert_equal('formatted message', message)
  end

  def test_inheritance_inherits_from_results_base
    assert_equal(Yard::Lint::Results::Base, Yard::Lint::Validators::Tags::ForbiddenTags::Result.superclass)
  end
end

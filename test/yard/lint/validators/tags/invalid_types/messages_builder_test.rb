# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsInvalidTypesMessagesBuilderTest < Minitest::Test

  def test_call_builds_message_for_invalid_tag_types
    offense = { method_name: 'calculate' }

    message = Yard::Lint::Validators::Tags::InvalidTypes::MessagesBuilder.call(offense)

    assert_equal('The `calculate` has at least one tag with an invalid type definition.', message)
  end

  def test_call_builds_message_for_class_method
    offense = { method_name: 'MyClass.validate' }

    message = Yard::Lint::Validators::Tags::InvalidTypes::MessagesBuilder.call(offense)

    assert_equal('The `MyClass.validate` has at least one tag with an invalid type definition.', message)
  end
end


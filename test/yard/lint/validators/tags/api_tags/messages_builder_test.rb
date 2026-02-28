# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsApiTagsMessagesBuilderTest < Minitest::Test

  def test_call_builds_message_for_missing_api_tag
    offense = {
      object_name: 'MyClass#method',
      status: 'missing'
    }

    message = Yard::Lint::Validators::Tags::ApiTags::MessagesBuilder.call(offense)

    assert_equal('Public object `MyClass#method` is missing @api tag', message)
  end

  def test_call_builds_message_for_invalid_api_tag_with_api_value
    offense = {
      object_name: 'MyClass#method',
      status: 'invalid:internal',
      api_value: 'internal'
    }

    message = Yard::Lint::Validators::Tags::ApiTags::MessagesBuilder.call(offense)

    assert_equal("Object `MyClass#method` has invalid @api tag value: 'internal'", message)
  end

  def test_call_builds_message_for_invalid_api_tag_from_status
    offense = {
      object_name: 'MyClass',
      status: 'invalid:deprecated'
    }

    message = Yard::Lint::Validators::Tags::ApiTags::MessagesBuilder.call(offense)

    assert_equal("Object `MyClass` has invalid @api tag value: 'deprecated'", message)
  end
end

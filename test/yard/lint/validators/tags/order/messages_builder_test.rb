# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsOrderMessagesBuilderTest < Minitest::Test

  def test_call_builds_message_for_invalid_tag_order
    offense = {
      method_name: 'calculate',
      order: 'param,return,raise'
    }

    message = Yard::Lint::Validators::Tags::Order::MessagesBuilder.call(offense)

    assert_equal(
      'The `calculate` has yard tags in an invalid order. ' \
      'Following tags need to be in the presented order: `param`, `return`, `raise`.',
      message
    )
  end

  def test_call_builds_message_with_single_tag
    offense = {
      method_name: 'process',
      order: 'param'
    }

    message = Yard::Lint::Validators::Tags::Order::MessagesBuilder.call(offense)

    assert_equal(
      'The `process` has yard tags in an invalid order. ' \
      'Following tags need to be in the presented order: `param`.',
      message
    )
  end
end


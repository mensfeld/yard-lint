# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsTagGroupSeparatorMessagesBuilderTest < Minitest::Test

  def test_call_with_single_missing_separator_generates_message_for_single_transition
    offense = {
      method_name: 'call',
      separators: 'param->return'
    }
    message = Yard::Lint::Validators::Tags::TagGroupSeparator::MessagesBuilder.call(offense)
    assert_equal(
      'The `call` is missing a blank line between `param` and `return` tag groups.',
      message
    )
  end

  def test_call_with_multiple_missing_separators_generates_message_listing_all_transitions
    offense = {
      method_name: 'process',
      separators: 'param->return,return->error'
    }
    message = Yard::Lint::Validators::Tags::TagGroupSeparator::MessagesBuilder.call(offense)
    assert_equal(
      'The `process` is missing blank lines between tag groups: ' \
      '`param` -> `return`, `return` -> `error`.',
      message
    )
  end

  def test_call_with_description_to_tag_transition_handles_description_group_in_message
    offense = {
      method_name: 'initialize',
      separators: 'description->param'
    }
    message = Yard::Lint::Validators::Tags::TagGroupSeparator::MessagesBuilder.call(offense)
    assert_equal(
      'The `initialize` is missing a blank line between `description` and `param` tag groups.',
      message
    )
  end
end

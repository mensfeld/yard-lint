# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsOptionTagsMessagesBuilderTest < Minitest::Test

  def test_call_builds_message_for_missing_option_tags
    offense = { method_name: 'initialize' }

    message = Yard::Lint::Validators::Tags::OptionTags::MessagesBuilder.call(offense)

    assert_equal(
      'Method `initialize` has options parameter but no @option tags ' \
      'documenting the available options',
      message
    )
  end

  def test_call_builds_message_for_instance_method
    offense = { method_name: 'MyClass#configure' }

    message = Yard::Lint::Validators::Tags::OptionTags::MessagesBuilder.call(offense)

    assert_equal(
      'Method `MyClass#configure` has options parameter but no @option tags ' \
      'documenting the available options',
      message
    )
  end
end

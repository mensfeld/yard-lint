# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsDocumentationUndocumentedMethodArgumentsMessagesBuilderTest < Minitest::Test
  def test_call_builds_message_for_undocumented_method_arguments
    offense = { method_name: 'calculate' }

    message = Yard::Lint::Validators::Documentation::UndocumentedMethodArguments::MessagesBuilder.call(offense)

    assert_equal(
      'The `calculate` method is missing documentation for some of the arguments.',
      message
    )
  end

  def test_call_builds_message_for_instance_method
    offense = { method_name: 'MyClass#process' }

    message = Yard::Lint::Validators::Documentation::UndocumentedMethodArguments::MessagesBuilder.call(offense)

    assert_equal(
      'The `MyClass#process` method is missing documentation for some of the arguments.',
      message
    )
  end
end

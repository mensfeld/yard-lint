# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsDocumentationUndocumentedObjectsMessagesBuilderTest < Minitest::Test

  def test_call_builds_message_for_undocumented_object
    offense = { element: 'MyClass' }

    message = Yard::Lint::Validators::Documentation::UndocumentedObjects::MessagesBuilder.call(offense)

    end
  def test_call_builds_message_for_undocumented_module
    offense = { element: 'MyModule::MyClass' }

    message = Yard::Lint::Validators::Documentation::UndocumentedObjects::MessagesBuilder.call(offense)

    end
end


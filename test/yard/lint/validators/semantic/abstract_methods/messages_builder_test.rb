# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsSemanticAbstractMethodsMessagesBuilderTest < Minitest::Test
  def test_call_builds_message_for_abstract_method_with_implementation
    offense = { method_name: 'MyClass#abstract_method' }

    message = Yard::Lint::Validators::Semantic::AbstractMethods::MessagesBuilder.call(offense)

    assert_equal(
      'Abstract method `MyClass#abstract_method` has implementation ' \
      '(should only raise NotImplementedError or be empty)',
      message
    )
  end

  def test_call_builds_message_for_class_method
    offense = { method_name: 'MyModule.abstract_factory' }

    message = Yard::Lint::Validators::Semantic::AbstractMethods::MessagesBuilder.call(offense)

    assert_equal(
      'Abstract method `MyModule.abstract_factory` has implementation ' \
      '(should only raise NotImplementedError or be empty)',
      message
    )
  end
end

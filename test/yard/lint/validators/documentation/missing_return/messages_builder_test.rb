# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsDocumentationMissingReturnMessagesBuilderTest < Minitest::Test
  def test_call_builds_message_for_instance_method
    offense = { element: 'Calculator#add' }
    message = Yard::Lint::Validators::Documentation::MissingReturn::MessagesBuilder.call(offense)

    assert_equal('Missing @return tag for `Calculator#add`', message)
  end

  def test_call_builds_message_for_class_method
    offense = { element: 'Calculator.new' }
    message = Yard::Lint::Validators::Documentation::MissingReturn::MessagesBuilder.call(offense)

    assert_equal('Missing @return tag for `Calculator.new`', message)
  end

  def test_call_builds_message_for_namespaced_class_instance_method
    offense = { element: 'Foo::Bar::Baz#method' }
    message = Yard::Lint::Validators::Documentation::MissingReturn::MessagesBuilder.call(offense)

    assert_equal('Missing @return tag for `Foo::Bar::Baz#method`', message)
  end

  def test_call_builds_message_for_method_with_special_characters
    offense = { element: 'Example#valid?' }
    message = Yard::Lint::Validators::Documentation::MissingReturn::MessagesBuilder.call(offense)

    assert_equal('Missing @return tag for `Example#valid?`', message)
  end

  def test_call_includes_element_name_in_backticks
    offense = { element: 'MyClass#my_method' }
    message = Yard::Lint::Validators::Documentation::MissingReturn::MessagesBuilder.call(offense)

    assert_includes(message, '`MyClass#my_method`')
  end

  def test_call_starts_with_missing_return_tag_for
    offense = { element: 'AnyClass#any_method' }
    message = Yard::Lint::Validators::Documentation::MissingReturn::MessagesBuilder.call(offense)

    assert(message.start_with?('Missing @return tag for'))
  end
end

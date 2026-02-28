# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsDocumentationEmptyCommentLineMessagesBuilderTest < Minitest::Test
  def test_call_with_leading_violation_returns_message
    offense = {
      location: 'lib/example.rb',
      line: 5,
      object_line: 10,
      object_name: 'MyClass#process',
      violation_type: 'leading'
    }

    message = Yard::Lint::Validators::Documentation::EmptyCommentLine::MessagesBuilder.call(offense)

    assert_equal("Empty leading comment line in documentation for 'MyClass#process'", message)
  end

  def test_call_with_trailing_violation_returns_message
    offense = {
      location: 'lib/example.rb',
      line: 9,
      object_line: 10,
      object_name: 'MyClass#execute',
      violation_type: 'trailing'
    }

    message = Yard::Lint::Validators::Documentation::EmptyCommentLine::MessagesBuilder.call(offense)

    assert_equal("Empty trailing comment line in documentation for 'MyClass#execute'", message)
  end

  def test_call_with_unknown_violation_type_returns_generic_message
    offense = {
      location: 'lib/example.rb',
      line: 5,
      object_line: 10,
      object_name: 'MyClass#unknown',
      violation_type: 'unknown'
    }

    message = Yard::Lint::Validators::Documentation::EmptyCommentLine::MessagesBuilder.call(offense)

    assert_equal("Empty comment line in documentation for 'MyClass#unknown'", message)
  end

  def test_error_descriptions_contains_leading_description
    assert(Yard::Lint::Validators::Documentation::EmptyCommentLine::MessagesBuilder::ERROR_DESCRIPTIONS.key?('leading'))
  end

  def test_error_descriptions_contains_trailing_description
    assert(Yard::Lint::Validators::Documentation::EmptyCommentLine::MessagesBuilder::ERROR_DESCRIPTIONS.key?('trailing'))
  end

  def test_error_descriptions_is_frozen
    assert_equal(true, Yard::Lint::Validators::Documentation::EmptyCommentLine::MessagesBuilder::ERROR_DESCRIPTIONS.frozen?)
  end
end

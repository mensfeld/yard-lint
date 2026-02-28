# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsDocumentationBlankLineBeforeDefinitionMessagesBuilderTest < Minitest::Test
  def test_call_with_single_blank_line_returns_message
    offense = {
      location: 'lib/example.rb',
      line: 10,
      object_name: 'MyClass#process',
      violation_type: 'single',
      blank_count: 1
    }

    message = Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::MessagesBuilder.call(offense)

    assert_equal("Blank line between documentation and definition for 'MyClass#process'", message)
  end

  def test_call_with_orphaned_documentation_returns_message
    offense = {
      location: 'lib/example.rb',
      line: 15,
      object_name: 'MyClass#execute',
      violation_type: 'orphaned',
      blank_count: 2
    }

    message = Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::MessagesBuilder.call(offense)

    assert_equal(
      "Documentation is orphaned (YARD ignores it due to blank lines) for 'MyClass#execute' (2 blank lines)",
      message
    )
  end

  def test_call_with_orphaned_documentation_and_3_blank_lines_includes_count
    offense = {
      location: 'lib/example.rb',
      line: 20,
      object_name: 'MyClass#run',
      violation_type: 'orphaned',
      blank_count: 3
    }

    message = Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::MessagesBuilder.call(offense)

    assert_includes(message, '3 blank lines')
  end

  def test_call_with_unknown_violation_type_returns_generic_message
    offense = {
      location: 'lib/example.rb',
      line: 5,
      object_name: 'MyClass#unknown',
      violation_type: 'unknown',
      blank_count: 1
    }

    message = Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::MessagesBuilder.call(offense)

    assert_equal("Blank line before definition for 'MyClass#unknown'", message)
  end

  def test_error_descriptions_contains_single_description
    assert(Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::MessagesBuilder::ERROR_DESCRIPTIONS.key?('single'))
  end

  def test_error_descriptions_contains_orphaned_description
    assert(Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::MessagesBuilder::ERROR_DESCRIPTIONS.key?('orphaned'))
  end

  def test_error_descriptions_is_frozen
    assert_equal(true, Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::MessagesBuilder::ERROR_DESCRIPTIONS.frozen?)
  end
end

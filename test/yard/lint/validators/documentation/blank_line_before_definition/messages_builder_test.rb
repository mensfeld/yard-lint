# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::MessagesBuilder' do
  it 'call with single blank line returns message' do
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

  it 'call with orphaned documentation returns message' do
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

  it 'call with orphaned documentation and 3 blank lines includes count' do
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

  it 'call with unknown violation type returns generic message' do
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

  it 'error descriptions contains single description' do
    assert(Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::MessagesBuilder::ERROR_DESCRIPTIONS.key?('single'))
  end

  it 'error descriptions contains orphaned description' do
    assert(Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::MessagesBuilder::ERROR_DESCRIPTIONS.key?('orphaned'))
  end

  it 'error descriptions is frozen' do
    assert_equal(true, Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::MessagesBuilder::ERROR_DESCRIPTIONS.frozen?)
  end
end


# frozen_string_literal: true

require 'test_helper'


describe 'Yard::Lint::Validators::Documentation::EmptyCommentLine::MessagesBuilder' do
  it 'call with leading violation returns message' do
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

  it 'call with trailing violation returns message' do
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

  it 'call with unknown violation type returns generic message' do
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

  it 'error descriptions contains leading description' do
    assert(Yard::Lint::Validators::Documentation::EmptyCommentLine::MessagesBuilder::ERROR_DESCRIPTIONS.key?('leading'))
  end

  it 'error descriptions contains trailing description' do
    assert(Yard::Lint::Validators::Documentation::EmptyCommentLine::MessagesBuilder::ERROR_DESCRIPTIONS.key?('trailing'))
  end

  it 'error descriptions is frozen' do
    assert_equal(true, Yard::Lint::Validators::Documentation::EmptyCommentLine::MessagesBuilder::ERROR_DESCRIPTIONS.frozen?)
  end
end

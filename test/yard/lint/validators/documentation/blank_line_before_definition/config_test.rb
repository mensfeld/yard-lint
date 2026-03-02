# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::Config' do
  it 'id returns the validator identifier' do
    assert_equal(
      :blank_line_before_definition,
      Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::Config.id
    )
  end

  it 'defaults returns default configuration' do
    assert_equal(
      {
        'Enabled' => true,
        'Severity' => 'convention',
        'OrphanedSeverity' => 'convention',
        'EnabledPatterns' => {
          'SingleBlankLine' => true,
          'OrphanedDocs' => true
        }
      },
      Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::Config.defaults
    )
  end

  it 'defaults returns frozen hash' do
    assert_predicate(Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::Config.defaults, :frozen?)
  end

  it 'combines with returns empty array for standalone validator' do
    assert_equal([], Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::Config.combines_with)
  end

  it 'inheritance inherits from base config class' do
    assert_equal(
      Yard::Lint::Validators::Config,
      Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::Config.superclass
    )
  end
end


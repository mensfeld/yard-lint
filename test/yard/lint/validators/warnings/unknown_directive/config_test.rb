# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Validators::Warnings::UnknownDirective::Config' do
  it 'id returns the validator identifier' do
    assert_equal(
      :unknown_directive,
      Yard::Lint::Validators::Warnings::UnknownDirective::Config.id
    )
  end

  it 'defaults returns default configuration' do
    assert_equal(
      {
        'Enabled' => true,
        'Severity' => 'error'
      },
      Yard::Lint::Validators::Warnings::UnknownDirective::Config.defaults
    )
  end

  it 'defaults returns frozen hash' do
    assert_predicate(Yard::Lint::Validators::Warnings::UnknownDirective::Config.defaults, :frozen?)
  end

  it 'combines with returns empty array for standalone validator' do
    assert_equal([], Yard::Lint::Validators::Warnings::UnknownDirective::Config.combines_with)
  end

  it 'inheritance inherits from base config class' do
    assert_equal(
      Yard::Lint::Validators::Config,
      Yard::Lint::Validators::Warnings::UnknownDirective::Config.superclass
    )
  end
end


# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Validators::Documentation::MissingReturn::Config' do
  it 'id returns the validator identifier' do
    assert_equal(
      :missing_return,
      Yard::Lint::Validators::Documentation::MissingReturn::Config.id
    )
  end

  it 'defaults returns default configuration' do
    assert_equal(
      {
        'Enabled' => false,
        'Severity' => 'warning',
        'ExcludedMethods' => ['initialize']
      },
      Yard::Lint::Validators::Documentation::MissingReturn::Config.defaults
    )
  end

  it 'defaults returns frozen hash' do
    assert_predicate(Yard::Lint::Validators::Documentation::MissingReturn::Config.defaults, :frozen?)
  end

  it 'defaults disables validator by default opt in' do
    assert_equal(false, Yard::Lint::Validators::Documentation::MissingReturn::Config.defaults['Enabled'])
  end

  it 'defaults excludes initialize methods by default' do
    assert_includes(
      Yard::Lint::Validators::Documentation::MissingReturn::Config.defaults['ExcludedMethods'],
      'initialize'
    )
  end

  it 'combines with returns empty array for standalone validator' do
    assert_equal([], Yard::Lint::Validators::Documentation::MissingReturn::Config.combines_with)
  end

  it 'inheritance inherits from base config class' do
    assert_equal(
      Yard::Lint::Validators::Config,
      Yard::Lint::Validators::Documentation::MissingReturn::Config.superclass
    )
  end
end


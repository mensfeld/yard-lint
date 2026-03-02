# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Validators::Semantic::AbstractMethods::Config' do
  it 'id returns the validator identifier' do
    assert_equal(
      :abstract_methods,
      Yard::Lint::Validators::Semantic::AbstractMethods::Config.id
    )
  end

  it 'defaults returns default configuration' do
    assert_equal(
      {
        'Enabled' => true,
        'Severity' => 'warning',
        'AllowedImplementations' => [
          'raise NotImplementedError',
          'raise NotImplementedError, ".+"'
        ]
      },
      Yard::Lint::Validators::Semantic::AbstractMethods::Config.defaults
    )
  end

  it 'defaults returns frozen hash' do
    assert_predicate(Yard::Lint::Validators::Semantic::AbstractMethods::Config.defaults, :frozen?)
  end

  it 'combines with returns empty array for standalone validator' do
    assert_equal([], Yard::Lint::Validators::Semantic::AbstractMethods::Config.combines_with)
  end

  it 'inheritance inherits from base config class' do
    assert_equal(
      Yard::Lint::Validators::Config,
      Yard::Lint::Validators::Semantic::AbstractMethods::Config.superclass
    )
  end
end


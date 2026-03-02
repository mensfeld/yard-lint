# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Validators::Tags::Order::Config' do
  it 'id returns the validator identifier' do
    assert_equal(:order, Yard::Lint::Validators::Tags::Order::Config.id)
  end

  it 'defaults returns default configuration' do
    assert_equal(
      {
        'Enabled' => true,
        'Severity' => 'convention',
        'EnforcedOrder' => %w[
          param
          option
          yield
          yieldparam
          yieldreturn
          return
          raise
          see
          example
          note
          todo
        ]
      },
      Yard::Lint::Validators::Tags::Order::Config.defaults
    )
  end

  it 'defaults returns frozen hash' do
    assert_predicate(Yard::Lint::Validators::Tags::Order::Config.defaults, :frozen?)
  end

  it 'combines with returns empty array for standalone validator' do
    assert_equal([], Yard::Lint::Validators::Tags::Order::Config.combines_with)
  end

  it 'inheritance inherits from base config class' do
    assert_equal(
      Yard::Lint::Validators::Config,
      Yard::Lint::Validators::Tags::Order::Config.superclass
    )
  end
end


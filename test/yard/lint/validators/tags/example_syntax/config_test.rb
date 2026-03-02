# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Validators::Tags::ExampleSyntax::Config' do
  it 'id returns the validator identifier' do
    assert_equal(:example_syntax, Yard::Lint::Validators::Tags::ExampleSyntax::Config.id)
  end

  it 'defaults returns default configuration' do
    assert_equal(
      {
        'Enabled' => true,
        'Severity' => 'warning'
      },
      Yard::Lint::Validators::Tags::ExampleSyntax::Config.defaults
    )
  end

  it 'defaults returns frozen hash' do
    assert_predicate(Yard::Lint::Validators::Tags::ExampleSyntax::Config.defaults, :frozen?)
  end

  it 'combines with returns empty array for standalone validator' do
    assert_equal([], Yard::Lint::Validators::Tags::ExampleSyntax::Config.combines_with)
  end

  it 'inheritance inherits from base config class' do
    assert_equal(
      Yard::Lint::Validators::Config,
      Yard::Lint::Validators::Tags::ExampleSyntax::Config.superclass
    )
  end
end


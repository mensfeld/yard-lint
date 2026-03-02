# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Validators::Tags::ExampleStyle::Config' do
  it 'id returns the validator identifier' do
    assert_equal(:example_style, Yard::Lint::Validators::Tags::ExampleStyle::Config.id)
  end

  it 'defaults returns default configuration' do
    assert_equal(
      {
        'Enabled' => false,
        'Severity' => 'convention',
        'Linter' => 'auto',
        'SkipPatterns' => [],
        'DisabledCops' => [
          'Style/FrozenStringLiteralComment',
          'Layout/TrailingWhitespace',
          'Layout/EndOfLine',
          'Layout/TrailingEmptyLines',
          'Metrics/MethodLength',
          'Metrics/AbcSize',
          'Metrics/CyclomaticComplexity',
          'Metrics/PerceivedComplexity'
        ]
      },
      Yard::Lint::Validators::Tags::ExampleStyle::Config.defaults
    )
  end

  it 'defaults returns frozen hash' do
    assert_predicate(Yard::Lint::Validators::Tags::ExampleStyle::Config.defaults, :frozen?)
  end

  it 'defaults is disabled by default opt in' do
    assert_equal(false, Yard::Lint::Validators::Tags::ExampleStyle::Config.defaults['Enabled'])
  end

  it 'defaults has convention severity by default' do
    assert_equal('convention', Yard::Lint::Validators::Tags::ExampleStyle::Config.defaults['Severity'])
  end

  it 'combines with returns empty array for standalone validator' do
    assert_equal([], Yard::Lint::Validators::Tags::ExampleStyle::Config.combines_with)
  end

  it 'inheritance inherits from base config class' do
    assert_equal(
      Yard::Lint::Validators::Config,
      Yard::Lint::Validators::Tags::ExampleStyle::Config.superclass
    )
  end
end


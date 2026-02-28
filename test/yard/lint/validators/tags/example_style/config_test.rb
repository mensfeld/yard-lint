# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsExampleStyleConfigTest < Minitest::Test
  def test_id_returns_the_validator_identifier
    assert_equal(:example_style, Yard::Lint::Validators::Tags::ExampleStyle::Config.id)
  end

  def test_defaults_returns_default_configuration
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

  def test_defaults_returns_frozen_hash
    assert_predicate(Yard::Lint::Validators::Tags::ExampleStyle::Config.defaults, :frozen?)
  end

  def test_defaults_is_disabled_by_default_opt_in
    assert_equal(false, Yard::Lint::Validators::Tags::ExampleStyle::Config.defaults['Enabled'])
  end

  def test_defaults_has_convention_severity_by_default
    assert_equal('convention', Yard::Lint::Validators::Tags::ExampleStyle::Config.defaults['Severity'])
  end

  def test_combines_with_returns_empty_array_for_standalone_validator
    assert_equal([], Yard::Lint::Validators::Tags::ExampleStyle::Config.combines_with)
  end

  def test_inheritance_inherits_from_base_config_class
    assert_equal(
      Yard::Lint::Validators::Config,
      Yard::Lint::Validators::Tags::ExampleStyle::Config.superclass
    )
  end
end

# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsExampleSyntaxConfigTest < Minitest::Test
  def test_id_returns_the_validator_identifier
    assert_equal(:example_syntax, Yard::Lint::Validators::Tags::ExampleSyntax::Config.id)
  end

  def test_defaults_returns_default_configuration
    assert_equal(
      {
        'Enabled' => true,
        'Severity' => 'warning'
      },
      Yard::Lint::Validators::Tags::ExampleSyntax::Config.defaults
    )
  end

  def test_defaults_returns_frozen_hash
    assert_predicate(Yard::Lint::Validators::Tags::ExampleSyntax::Config.defaults, :frozen?)
  end

  def test_combines_with_returns_empty_array_for_standalone_validator
    assert_equal([], Yard::Lint::Validators::Tags::ExampleSyntax::Config.combines_with)
  end

  def test_inheritance_inherits_from_base_config_class
    assert_equal(
      Yard::Lint::Validators::Config,
      Yard::Lint::Validators::Tags::ExampleSyntax::Config.superclass
    )
  end
end

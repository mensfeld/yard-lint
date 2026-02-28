# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsWarningsUnknownDirectiveConfigTest < Minitest::Test
  def test_id_returns_the_validator_identifier
    assert_equal(
      :unknown_directive,
      Yard::Lint::Validators::Warnings::UnknownDirective::Config.id
    )
  end

  def test_defaults_returns_default_configuration
    assert_equal(
      {
        'Enabled' => true,
        'Severity' => 'error'
      },
      Yard::Lint::Validators::Warnings::UnknownDirective::Config.defaults
    )
  end

  def test_defaults_returns_frozen_hash
    assert_predicate(Yard::Lint::Validators::Warnings::UnknownDirective::Config.defaults, :frozen?)
  end

  def test_combines_with_returns_empty_array_for_standalone_validator
    assert_equal([], Yard::Lint::Validators::Warnings::UnknownDirective::Config.combines_with)
  end

  def test_inheritance_inherits_from_base_config_class
    assert_equal(
      Yard::Lint::Validators::Config,
      Yard::Lint::Validators::Warnings::UnknownDirective::Config.superclass
    )
  end
end

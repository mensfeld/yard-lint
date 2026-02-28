# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsDocumentationMissingReturnConfigTest < Minitest::Test
  def test_id_returns_the_validator_identifier
    assert_equal(
      :missing_return,
      Yard::Lint::Validators::Documentation::MissingReturn::Config.id
    )
  end

  def test_defaults_returns_default_configuration
    assert_equal(
      {
        'Enabled' => false,
        'Severity' => 'warning',
        'ExcludedMethods' => ['initialize']
      },
      Yard::Lint::Validators::Documentation::MissingReturn::Config.defaults
    )
  end

  def test_defaults_returns_frozen_hash
    assert_predicate(Yard::Lint::Validators::Documentation::MissingReturn::Config.defaults, :frozen?)
  end

  def test_defaults_disables_validator_by_default_opt_in
    assert_equal(false, Yard::Lint::Validators::Documentation::MissingReturn::Config.defaults['Enabled'])
  end

  def test_defaults_excludes_initialize_methods_by_default
    assert_includes(
      Yard::Lint::Validators::Documentation::MissingReturn::Config.defaults['ExcludedMethods'],
      'initialize'
    )
  end

  def test_combines_with_returns_empty_array_for_standalone_validator
    assert_equal([], Yard::Lint::Validators::Documentation::MissingReturn::Config.combines_with)
  end

  def test_inheritance_inherits_from_base_config_class
    assert_equal(
      Yard::Lint::Validators::Config,
      Yard::Lint::Validators::Documentation::MissingReturn::Config.superclass
    )
  end
end

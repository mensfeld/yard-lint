# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsDocumentationUndocumentedObjectsConfigTest < Minitest::Test
  def test_id_returns_the_validator_identifier
    assert_equal(
      :undocumented_objects,
      Yard::Lint::Validators::Documentation::UndocumentedObjects::Config.id
    )
  end

  def test_defaults_returns_default_configuration
    assert_equal(
      {
        'Enabled' => true,
        'Severity' => 'warning',
        'ExcludedMethods' => ['initialize/0']
      },
      Yard::Lint::Validators::Documentation::UndocumentedObjects::Config.defaults
    )
  end

  def test_defaults_returns_frozen_hash
    assert_predicate(Yard::Lint::Validators::Documentation::UndocumentedObjects::Config.defaults, :frozen?)
  end

  def test_combines_with_combines_with_undocumented_boolean_methods_validator
    assert_equal(
      ['Documentation/UndocumentedBooleanMethods'],
      Yard::Lint::Validators::Documentation::UndocumentedObjects::Config.combines_with
    )
  end

  def test_combines_with_returns_frozen_array
    assert_predicate(Yard::Lint::Validators::Documentation::UndocumentedObjects::Config.combines_with, :frozen?)
  end

  def test_inheritance_inherits_from_base_config_class
    assert_equal(
      Yard::Lint::Validators::Config,
      Yard::Lint::Validators::Documentation::UndocumentedObjects::Config.superclass
    )
  end
end

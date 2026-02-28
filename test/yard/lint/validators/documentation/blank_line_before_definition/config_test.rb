# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsDocumentationBlankLineBeforeDefinitionConfigTest < Minitest::Test
  def test_id_returns_the_validator_identifier
    assert_equal(
      :blank_line_before_definition,
      Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::Config.id
    )
  end

  def test_defaults_returns_default_configuration
    assert_equal(
      {
        'Enabled' => true,
        'Severity' => 'convention',
        'OrphanedSeverity' => 'convention',
        'EnabledPatterns' => {
          'SingleBlankLine' => true,
          'OrphanedDocs' => true
        }
      },
      Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::Config.defaults
    )
  end

  def test_defaults_returns_frozen_hash
    assert_predicate(Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::Config.defaults, :frozen?)
  end

  def test_combines_with_returns_empty_array_for_standalone_validator
    assert_equal([], Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::Config.combines_with)
  end

  def test_inheritance_inherits_from_base_config_class
    assert_equal(
      Yard::Lint::Validators::Config,
      Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::Config.superclass
    )
  end
end

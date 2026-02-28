# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsTypeSyntaxConfigTest < Minitest::Test
  def test_id_returns_type_syntax
    assert_equal(:type_syntax, Yard::Lint::Validators::Tags::TypeSyntax::Config.id)
  end

  def test_defaults_has_enabled_set_to_true
    assert_equal(true, Yard::Lint::Validators::Tags::TypeSyntax::Config.defaults['Enabled'])
  end

  def test_defaults_has_severity_set_to_warning
    assert_equal('warning', Yard::Lint::Validators::Tags::TypeSyntax::Config.defaults['Severity'])
  end

  def test_defaults_has_validatedtags_with_param_option_return_yieldreturn
    expected_tags = %w[param option return yieldreturn]
    assert_equal(expected_tags, Yard::Lint::Validators::Tags::TypeSyntax::Config.defaults['ValidatedTags'])
  end

  def test_defaults_is_frozen
    assert_predicate(Yard::Lint::Validators::Tags::TypeSyntax::Config.defaults, :frozen?)
  end

  def test_inheritance_inherits_from_validators_config
    assert_equal(
      Yard::Lint::Validators::Config,
      Yard::Lint::Validators::Tags::TypeSyntax::Config.superclass
    )
  end
end

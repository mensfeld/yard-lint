# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsRedundantParamDescriptionConfigTest < Minitest::Test
  def test_id_returns_the_validator_identifier
    assert_equal(
      :redundant_param_description,
      Yard::Lint::Validators::Tags::RedundantParamDescription::Config.id
    )
  end

  def test_defaults_returns_default_configuration
    defaults = Yard::Lint::Validators::Tags::RedundantParamDescription::Config.defaults

    assert_equal(true, defaults['Enabled'])
    assert_equal('convention', defaults['Severity'])
    assert_equal(%w[param option], defaults['CheckedTags'])
    assert_equal(%w[The the A a An an], defaults['Articles'])
    assert_equal(6, defaults['MaxRedundantWords'])
    assert_equal(%w[object instance value data item element], defaults['GenericTerms'])
    assert_equal(%w[being to that which for], defaults['LowValueConnectors'])
    assert_includes(defaults['LowValueVerbs'], 'perform')
    assert_includes(defaults['LowValueVerbs'], 'performed')
    assert_includes(defaults['LowValueVerbs'], 'performing')
    assert_includes(defaults['LowValueVerbs'], 'invoke')
    assert_includes(defaults['LowValueVerbs'], 'invoked')
    assert_includes(defaults['LowValueVerbs'], 'invoking')
  end

  def test_defaults_includes_all_pattern_toggles
    patterns = Yard::Lint::Validators::Tags::RedundantParamDescription::Config.defaults['EnabledPatterns']

    assert_equal(true, patterns['ArticleParam'])
    assert_equal(true, patterns['PossessiveParam'])
    assert_equal(true, patterns['TypeRestatement'])
    assert_equal(true, patterns['ParamToVerb'])
    assert_equal(true, patterns['IdPattern'])
    assert_equal(true, patterns['DirectionalDate'])
    assert_equal(true, patterns['TypeGeneric'])
    assert_equal(true, patterns['ArticleParamPhrase'])
  end

  def test_defaults_returns_frozen_hash
    assert_predicate(Yard::Lint::Validators::Tags::RedundantParamDescription::Config.defaults, :frozen?)
  end

  def test_combines_with_returns_empty_array_for_standalone_validator
    assert_equal([], Yard::Lint::Validators::Tags::RedundantParamDescription::Config.combines_with)
  end

  def test_inheritance_inherits_from_base_config_class
    assert_equal(
      Yard::Lint::Validators::Config,
      Yard::Lint::Validators::Tags::RedundantParamDescription::Config.superclass
    )
  end
end

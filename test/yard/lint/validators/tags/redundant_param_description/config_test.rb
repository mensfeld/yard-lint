# frozen_string_literal: true

describe 'Yard::Lint::Validators::Tags::RedundantParamDescription::Config' do
  it 'id returns the validator identifier' do
    assert_equal(
      :redundant_param_description,
      Yard::Lint::Validators::Tags::RedundantParamDescription::Config.id
    )
  end

  it 'defaults returns default configuration' do
    defaults = Yard::Lint::Validators::Tags::RedundantParamDescription::Config.defaults

    assert_equal(true, defaults['Enabled'])
    assert_equal('convention', defaults['Severity'])
    assert_equal(%w[param option], defaults['CheckedTags'])
    assert_equal(%w[The the A a An an], defaults['Articles'])
    assert_equal(6, defaults['MaxRedundantWords'])
    assert_equal(%w[object instance value data item element], defaults['GenericTerms'])
    assert_equal(%w[being to that which for], defaults['LowValueConnectors'])
  end

  it 'defaults includes all pattern toggles' do
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

  it 'defaults returns frozen hash' do
    assert_predicate(Yard::Lint::Validators::Tags::RedundantParamDescription::Config.defaults, :frozen?)
  end

  it 'combines with returns empty array for standalone validator' do
    assert_equal([], Yard::Lint::Validators::Tags::RedundantParamDescription::Config.combines_with)
  end

  it 'inheritance inherits from base config class' do
    assert_equal(
      Yard::Lint::Validators::Config,
      Yard::Lint::Validators::Tags::RedundantParamDescription::Config.superclass
    )
  end
end


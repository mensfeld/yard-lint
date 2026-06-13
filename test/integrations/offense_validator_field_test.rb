# frozen_string_literal: true

# Proves that Semantic/AbstractMethods and Tags/OptionTags offenses carry the
# `:validator` field (the full config key). Both validators override
# Results::Base#build_offenses and omitted the `validator: validator_name`
# merge the base class performs, so their offenses had no validator path -
# the text/quickfix formatters print an empty validator for them.
describe 'Offense validator field' do
  attr_reader :result

  before do
    fixture_path = File.expand_path('../fixtures/offense_validator_field.rb', __dir__)
    config = test_config do |c|
      c.set_validator_config('Semantic/AbstractMethods', 'Enabled', true)
      c.set_validator_config('Tags/OptionTags', 'Enabled', true)
    end
    @result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
  end

  it 'sets the validator field on AbstractMethods offenses' do
    offense = result.offenses.find { |o| o[:name] == 'AbstractMethod' }

    refute_nil(offense)
    assert_equal('Semantic/AbstractMethods', offense[:validator])
  end

  it 'sets the validator field on OptionTags offenses' do
    offense = result.offenses.find { |o| o[:name] == 'MissingOptionTags' }

    refute_nil(offense)
    assert_equal('Tags/OptionTags', offense[:validator])
  end
end

# frozen_string_literal: true

# Proves that Tags/OptionTags does not demand @option tags for a parameter
# that merely has an options-like name but is documented as a non-Hash type.
# The check looked only at the parameter name, so a boolean keyword argument
# or an array parameter named `options`/`opts` was wrongly required to have
# @option tags.
describe 'OptionTags non-hash parameters' do
  attr_reader :result

  before do
    fixture_path = File.expand_path('../fixtures/option_tags_non_hash.rb', __dir__)
    config = test_config do |c|
      c.set_validator_config('Tags/OptionTags', 'Enabled', true)
    end
    @result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
  end

  def flagged?(method_name)
    result.offenses.any? do |o|
      o[:name] == 'MissingOptionTags' && o[:message].include?("##{method_name}`")
    end
  end

  it 'does not flag a boolean keyword argument named options' do
    refute(flagged?('run_flag'), 'a Boolean param named options was required to have @option tags')
  end

  it 'does not flag an array parameter named opts' do
    refute(flagged?('process'), 'an Array param named opts was required to have @option tags')
  end

  it 'still flags a genuine options hash with no @option tags' do
    assert(flagged?('configure'))
  end
end

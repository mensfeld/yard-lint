# frozen_string_literal: true

# Proves that RedundantParamDescription's ParamToVerb pattern only fires when
# the word after "to" is actually a low-value verb. It previously flagged any
# "<param> to <anything>", so meaningful noun phrases like "path to file" were
# reported as too generic.
describe 'RedundantParamDescription ParamToVerb' do
  attr_reader :result

  before do
    fixture_path = File.expand_path('../fixtures/param_to_verb.rb', __dir__)
    @result = Yard::Lint.run(path: fixture_path, config: test_config, progress: false)
  end

  def flagged?(desc)
    result.offenses.any? do |o|
      o[:name] == 'RedundantParamDescription' && o[:message].include?("'#{desc}'")
    end
  end

  it 'does not flag a noun phrase like "path to file"' do
    refute(flagged?('path to file'), '"path to file" was flagged as too generic')
  end

  it 'still flags "<param> to <low-value verb>"' do
    assert(flagged?('user to process'))
  end
end

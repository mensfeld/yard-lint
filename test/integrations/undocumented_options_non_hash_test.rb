# frozen_string_literal: true

# Proves that Documentation/UndocumentedOptions does not demand @option tags
# for a named parameter that merely matches an options-like name but is
# documented as a non-Hash type. The check looked only at the parameter name.
describe 'UndocumentedOptions non-hash parameters' do
  attr_reader :result

  before do
    fixture_path = File.expand_path('../fixtures/undocumented_options_non_hash.rb', __dir__)
    config = test_config { |c| c.set_validator_config('Documentation/UndocumentedOptions', 'Enabled', true) }
    @result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
  end

  def flagged?(method_name)
    result.offenses.any? do |o|
      o[:name] == 'UndocumentedOptions' && o[:message].include?("##{method_name}'")
    end
  end

  it 'does not flag a scalar param documented as a non-Hash type' do
    refute(flagged?('enable'), 'a Symbol param named option was required to document @option')
  end

  it 'still flags a genuine options hash with no @option tags' do
    assert(flagged?('configure'))
  end
end

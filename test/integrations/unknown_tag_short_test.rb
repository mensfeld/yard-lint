# frozen_string_literal: true

# Proves that Warnings/UnknownTag does not offer an absurd "did you mean"
# suggestion for a short tag that is very different from every real tag. The
# Levenshtein fallback allowed up to half the length, so @spec was "corrected"
# to @see and @foo to @todo.
describe 'UnknownTag short-name suggestions' do
  it 'does not suggest a distant tag for a short unknown tag' do
    fixture_path = File.expand_path('../fixtures/unknown_tag_short.rb', __dir__)
    config = test_config { |c| c.set_validator_config('Warnings/UnknownTag', 'Enabled', true) }
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find { |o| o[:name] == 'UnknownTag' && o[:message].include?('@spec') }
    refute_nil(offense)
    refute_includes(offense[:message], 'did you mean', "offered an absurd suggestion: #{offense[:message]}")
  end
end

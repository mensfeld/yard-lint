# frozen_string_literal: true

# Proves that Tags/ApiTags validates only the @api value itself, not any
# indented continuation/description lines. YARD's tag text includes
# continuation lines, so `@api private` followed by a description produced
# text like "private\nfor internal use only", which failed the allowed-value
# check (false "invalid @api value" offense) and - because the emitted value
# contained a newline - corrupted the parser's two-line pairing, dropping
# later offenses.
describe 'ApiTags continuation lines' do
  attr_reader :result

  before do
    fixture_path = File.expand_path('../fixtures/api_tag_continuation.rb', __dir__)
    config = test_config do |c|
      c.set_validator_config('Tags/ApiTags', 'Enabled', true)
    end
    @result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
  end

  def invalid_api_for(object_name)
    result.offenses.find do |o|
      o[:name] == 'ApiTag' &&
        o[:message].include?('invalid') &&
        o[:message].include?("#{object_name}`")
    end
  end

  it 'does not flag @api private when followed by a description line' do
    assert_nil(invalid_api_for('helper'), '@api private with a continuation line was treated as invalid')
    assert_nil(invalid_api_for('ApiTagContinuation'), 'class @api private with a continuation line was treated as invalid')
  end

  it 'still flags a genuinely invalid @api value' do
    offense = invalid_api_for('weird')

    refute_nil(offense)
    assert_includes(offense[:message], "'bogus'")
  end
end

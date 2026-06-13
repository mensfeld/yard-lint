# frozen_string_literal: true

# Proves that Tags/InformalNotation suggests @note (not @deprecated) for a
# "Warning:" notation - a warning is a caveat/note, not a deprecation.
describe 'InformalNotation Warning mapping' do
  it 'suggests @note for a Warning: notation' do
    fixture_path = File.expand_path('../fixtures/informal_warning_note.rb', __dir__)
    config = test_config { |c| c.set_validator_config('Tags/InformalNotation', 'Enabled', true) }
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find do |o|
      o[:name] == 'InformalNotation' && o[:message].include?("'Warning:'")
    end
    refute_nil(offense)
    assert_includes(offense[:message], '@note')
    refute_includes(offense[:message], '@deprecated')
  end
end

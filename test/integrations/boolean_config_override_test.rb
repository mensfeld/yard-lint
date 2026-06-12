# frozen_string_literal: true

# Proves that a user-configured `false` overrides a truthy validator default.
# `Tags/InformalNotation` has `RequireStartOfLine: true` by default; the fixture
# contains an informal `Note:` only mid-line, which is reported exclusively when
# the user successfully sets `RequireStartOfLine: false`.
describe 'Boolean config override' do
  attr_reader :fixture_path

  before do
    @fixture_path = File.expand_path('../fixtures/informal_notation_midline.rb', __dir__)
  end

  it 'honors a user-configured false for a boolean option with a truthy default' do
    config = test_config do |c|
      c.set_validator_config('Tags/InformalNotation', 'Enabled', true)
      c.set_validator_config('Tags/InformalNotation', 'RequireStartOfLine', false)
    end

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    informal_offenses = result.offenses.select { |o| o[:name] == 'InformalNotation' }

    refute_empty(
      informal_offenses,
      'RequireStartOfLine: false was ignored - mid-line informal notation not reported'
    )
    assert_includes(informal_offenses.first[:message], "'Note:'")
  end

  it 'keeps the truthy default when the user does not override it' do
    config = test_config do |c|
      c.set_validator_config('Tags/InformalNotation', 'Enabled', true)
    end

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    informal_offenses = result.offenses.select { |o| o[:name] == 'InformalNotation' }

    assert_empty(
      informal_offenses,
      'mid-line informal notation must not be reported with default RequireStartOfLine: true'
    )
  end
end

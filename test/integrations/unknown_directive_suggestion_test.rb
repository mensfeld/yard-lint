# frozen_string_literal: true

# Proves that Warnings/UnknownTag renders a "did you mean" suggestion that is
# actually a YARD directive with the `@!` prefix, not a plain `@`. The
# suggestion dictionary merges tags and directives, but every suggestion was
# rendered as `@name`, so a directive suggestion (e.g. `parse`) came out as
# `@parse` - following it just produces another unknown-tag offense, because
# the valid form is the directive `@!parse`.
describe 'UnknownTag directive suggestion' do
  attr_reader :result

  before do
    fixture_path = File.expand_path('../fixtures/unknown_directive_suggestion.rb', __dir__)
    config = test_config do |c|
      c.set_validator_config('Warnings/UnknownTag', 'Enabled', true)
    end
    @result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
  end

  it 'renders a directive suggestion with the @! prefix' do
    offense = result.offenses.find do |o|
      o[:name] == 'UnknownTag' && o[:message].include?('@parsee')
    end

    refute_nil(offense)
    assert_includes(offense[:message], "@!parse")
    refute_includes(offense[:message], "mean '@parse'")
  end
end

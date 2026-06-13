# frozen_string_literal: true

# Proves that Tags/NonAsciiType does not flag non-ASCII characters inside
# string or quoted-symbol literal types (e.g. ["naïve", "plain"]). Those are
# values, not Ruby type names, so non-ASCII is legitimate - only real type
# names must be ASCII.
describe 'NonAsciiType string literals' do
  attr_reader :result

  before do
    fixture_path = File.expand_path('../fixtures/non_ascii_string_literal.rb', __dir__)
    config = test_config { |c| c.set_validator_config('Tags/NonAsciiType', 'Enabled', true) }
    @result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
  end

  def offenses
    result.offenses.select { |o| o[:name] == 'NonAsciiType' }
  end

  it 'does not flag non-ASCII inside a string-literal type' do
    refute(offenses.any? { |o| o[:message].include?('"naïve"') }, 'a string-literal type was flagged')
  end

  it 'still flags non-ASCII in a real type name' do
    assert(offenses.any? { |o| o[:message].include?('Strïng') })
  end
end

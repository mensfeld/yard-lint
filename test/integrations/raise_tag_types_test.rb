# frozen_string_literal: true

# Regression test: @raise tag types were not included in ValidatedTags for any
# type validator, meaning type errors in @raise tags were never caught.
describe 'Raise Tag Types' do
  attr_reader :fixture_path, :config

  before do
    @fixture_path = File.expand_path('../fixtures/raise_tag_types.rb', __dir__)
    @config = test_config do |c|
      c.set_validator_config('Tags/InvalidTypes', 'Enabled', true)
      c.set_validator_config('Tags/TypeSyntax', 'Enabled', true)
    end
  end

  it 'does not flag valid exception types in @raise tags' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offenses = result.offenses.select do |o|
      (o[:name] == 'InvalidTagType' || o[:name] == 'InvalidTypeSyntax') &&
        o[:method_name]&.end_with?('valid_raise')
    end

    assert_empty(
      offenses,
      "Valid @raise types should not be flagged: #{offenses.map { |o| o[:message] }}"
    )
  end

  it 'flags type syntax errors in @raise tags' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find do |o|
      o[:name] == 'InvalidTypeSyntax' && o[:method_name]&.include?('invalid_raise_syntax')
    end

    refute_nil(offense, 'Malformed type in @raise should be flagged as InvalidTypeSyntax')
  end
end

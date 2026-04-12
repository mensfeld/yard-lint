# frozen_string_literal: true

# Regression test: @yieldparam was missing from ValidatedTags in InvalidTypes,
# TypeSyntax, and CollectionType validators, meaning types in @yieldparam tags
# were not validated for correctness.
describe 'Yieldparam Types' do
  attr_reader :fixture_path, :config

  before do
    @fixture_path = File.expand_path('../fixtures/yieldparam_types.rb', __dir__)
    @config = test_config do |c|
      c.set_validator_config('Tags/InvalidTypes', 'Enabled', true)
      c.set_validator_config('Tags/TypeSyntax', 'Enabled', true)
    end
  end

  it 'does not flag valid types in @yieldparam tags' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offenses = result.offenses.select do |o|
      (o[:name] == 'InvalidTagType' || o[:name] == 'InvalidTypeSyntax') &&
        o[:method_name]&.include?('each_with_index')
    end

    assert_empty(
      offenses,
      "Valid @yieldparam types should not be flagged: #{offenses.map { |o| o[:message] }}"
    )
  end

  it 'flags type syntax errors in @yieldparam tags' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find do |o|
      o[:name] == 'InvalidTypeSyntax' && o[:method_name]&.include?('each_invalid')
    end

    refute_nil(offense, 'Malformed type in @yieldparam should be flagged as InvalidTypeSyntax')
  end
end

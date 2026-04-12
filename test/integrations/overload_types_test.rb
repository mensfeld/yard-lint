# frozen_string_literal: true

# Regression test: type validators did not inspect tags inside @overload blocks.
# YARD stores @overload inner tags on the overload's own docstring, making them
# invisible to validators that only traverse object.docstring.tags.
describe 'Overload Types' do
  attr_reader :config

  describe 'valid types inside @overload' do
    attr_reader :fixture_path

    before do
      @fixture_path = File.expand_path('../fixtures/overload_types.rb', __dir__)
      @config = test_config do |c|
        c.set_validator_config('Tags/InvalidTypes', 'Enabled', true)
        c.set_validator_config('Tags/TypeSyntax', 'Enabled', true)
        c.set_validator_config('Tags/CollectionType', 'Enabled', true)
        c.set_validator_config('Tags/NonAsciiType', 'Enabled', true)
      end
    end

    it 'does not flag valid types inside @overload blocks as InvalidTagType' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offenses = result.offenses.select { |o| o[:name] == 'InvalidTagType' }

      assert_empty(
        offenses,
        "Expected no InvalidTagType offenses but got: #{offenses.map { |o| o[:message] }}"
      )
    end

    it 'does not flag valid types inside @overload blocks as InvalidTypeSyntax' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offenses = result.offenses.select { |o| o[:name] == 'InvalidTypeSyntax' }

      assert_empty(
        offenses,
        "Expected no InvalidTypeSyntax offenses but got: #{offenses.map { |o| o[:message] }}"
      )
    end
  end

  describe 'invalid type syntax inside @overload' do
    attr_reader :fixture_path

    before do
      @fixture_path = File.expand_path('../fixtures/overload_invalid_types.rb', __dir__)
      @config = test_config do |c|
        c.set_validator_config('Tags/TypeSyntax', 'Enabled', true)
      end
    end

    it 'detects type syntax errors inside @overload blocks' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offenses = result.offenses.select { |o| o[:name] == 'InvalidTypeSyntax' }

      refute_empty(
        offenses,
        'Expected InvalidTypeSyntax offenses for malformed types inside @overload blocks'
      )
    end

    it 'flags empty generic inside @overload @param' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:method_name]&.include?('convert')
      end

      refute_nil(offense, 'Empty generic Array<> inside @overload @param should be flagged')
    end
  end
end

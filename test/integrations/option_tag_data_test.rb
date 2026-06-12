# frozen_string_literal: true

# Proves that @option tag types and descriptions are validated. YARD's
# OptionTag stores its data on the nested pair tag (tag.pair.types /
# tag.pair.text) - tag.types and tag.text are nil on the OptionTag itself,
# so validators reading those accessors directly silently skipped every
# @option tag despite listing 'option' in their ValidatedTags/CheckedTags.
describe 'Option tag data' do
  attr_reader :result

  before do
    fixture_path = File.expand_path('../fixtures/option_tag_data.rb', __dir__)
    config = test_config do |c|
      c.set_validator_config('Tags/ForbiddenTags', 'Enabled', true)
      c.set_validator_config(
        'Tags/ForbiddenTags',
        'ForbiddenPatterns',
        [{ 'Tag' => 'option', 'Types' => ['Object'] }]
      )
    end
    @result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
  end

  it 'validates types of @option tags' do
    offenses = result.offenses.select do |o|
      o[:name] == 'InvalidTagType' && o[:message].include?('`strng`')
    end

    refute_empty(offenses, 'invalid type in an @option tag was not validated')

    assert_includes(offenses.first[:message], 'option')
  end

  it 'enforces collection style in @option tag types' do
    offenses = result.offenses.select do |o|
      o[:name] == 'CollectionType' && o[:message].include?('Hash<Symbol, String>')
    end

    refute_empty(offenses, 'collection style in an @option tag was not checked')

    assert_includes(offenses.first[:message], 'Hash{Symbol => String}')
  end

  it 'matches forbidden type patterns in @option tags' do
    offenses = result.offenses.select { |o| o[:name] == 'ForbiddenTags' }

    refute_empty(offenses, 'forbidden type in an @option tag escaped detection')

    assert_includes(offenses.first[:message], '@option')
  end

  it 'checks @option descriptions for redundancy' do
    offenses = result.offenses.select do |o|
      o[:name] == 'RedundantParamDescription' && o[:message].include?("'the name'")
    end

    refute_empty(offenses, 'redundant @option description was not checked')

    assert_includes(offenses.first[:message], '@option')
  end
end

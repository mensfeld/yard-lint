# frozen_string_literal: true

# Proves that tags written inside @overload blocks count as documentation.
# YARD stores them on the overload's own docstring, so validators reading
# object.tags/object.docstring.tags directly used to miss them: methods fully
# documented via @overload were flagged for missing @param/@return/@option
# tags, and forbidden tags hidden inside overloads escaped detection.
describe 'Overload documented methods' do
  attr_reader :result

  before do
    fixture_path = File.expand_path('../fixtures/overload_documented.rb', __dir__)
    config = test_config do |c|
      c.set_validator_config('Documentation/MissingReturn', 'Enabled', true)
      c.set_validator_config('Tags/ForbiddenTags', 'Enabled', true)
      c.set_validator_config(
        'Tags/ForbiddenTags',
        'ForbiddenPatterns',
        [{ 'Tag' => 'param', 'Types' => ['Object'] }]
      )
    end
    @result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
  end

  it 'does not flag params documented inside @overload blocks' do
    offenses = result.offenses.select { |o| o[:name] == 'UndocumentedMethodArgument' }

    assert_empty(offenses, '@param tags inside @overload blocks were not counted')
  end

  it 'does not flag a @return documented inside an @overload block' do
    offenses = result.offenses.select do |o|
      o[:name] == 'MissingReturnTag' && o[:message].include?('fetch')
    end

    assert_empty(offenses, '@return tag inside an @overload block was not counted')
  end

  it 'does not flag @option tags documented inside @overload blocks' do
    offenses = result.offenses.select { |o| o[:name] == 'MissingOptionTags' }

    assert_empty(offenses, '@option tags inside @overload blocks were not counted')
  end

  it 'detects forbidden tags inside @overload blocks' do
    offenses = result.offenses.select { |o| o[:name] == 'ForbiddenTags' }

    refute_empty(offenses, 'forbidden tags inside @overload blocks escaped detection')

    assert_includes(offenses.first[:message], '@param [Object]')
  end
end

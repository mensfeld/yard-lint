# frozen_string_literal: true

# Proves that offenses on top-level (root namespace) methods and on constants
# are reported. Their YARD titles (#method_name, CONST_NAME) have no
# Class#method separator, which the location regex used by the
# UndocumentedMethodArguments and InvalidTypes parsers used to require,
# silently discarding such offenses (and, via the shared parser, Tags/Order
# locations too).
describe 'Top-level and constant offenses' do
  attr_reader :fixture_path, :result

  before do
    @fixture_path = File.expand_path('../fixtures/top_level_offenses.rb', __dir__)
    config = test_config
    @result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
  end

  it 'reports undocumented arguments of a top-level method' do
    offenses = result.offenses.select do |o|
      o[:name] == 'UndocumentedMethodArgument' &&
        o[:message].include?('top_level_partially_documented')
    end

    refute_empty(offenses, 'offense on a top-level method was dropped by the parser')

    assert_operator(offenses.first[:line], :>, 0)
  end

  it 'reports an invalid tag type on a top-level method' do
    offenses = result.offenses.select do |o|
      o[:name] == 'InvalidTagType' &&
        o[:message].include?('top_level_invalid_type')
    end

    refute_empty(offenses, 'offense on a top-level method was dropped by the parser')

    assert_includes(offenses.first[:message], '`strng`')
  end

  it 'reports an invalid tag type on a constant' do
    offenses = result.offenses.select do |o|
      o[:name] == 'InvalidTagType' &&
        o[:message].include?('TOP_LEVEL_BAD_CONST')
    end

    refute_empty(offenses, 'offense on a constant was dropped by the parser')

    assert_includes(offenses.first[:message], '`strng`')
  end

  it 'reports wrong tag order on a top-level method with its own expected order' do
    offenses = result.offenses.select do |o|
      o[:name] == 'InvalidTagOrder' &&
        o[:message].include?('top_level_wrong_tag_order')
    end

    refute_empty(offenses, 'offense on a top-level method was dropped by the parser')

    # The expected order must belong to this method (param before return),
    # not to another offense shifted by a dropped location line
    assert_includes(offenses.first[:message], '`param`, `return`')
  end
end

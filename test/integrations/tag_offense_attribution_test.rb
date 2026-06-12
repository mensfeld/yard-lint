# frozen_string_literal: true

# Proves that each Tags/Order and Tags/TagGroupSeparator offense carries its
# own payload (expected order / missing separators). The parsers used to zip
# two parallel arrays by index, so a single dropped location line shifted
# every following offense onto another object's payload.
describe 'Tag offense attribution' do
  attr_reader :result

  before do
    fixture_path = File.expand_path('../fixtures/tag_offense_attribution.rb', __dir__)
    config = test_config do |c|
      c.set_validator_config('Tags/TagGroupSeparator', 'Enabled', true)
    end
    @result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
  end

  it 'reports each wrong tag order with its own expected order' do
    read_offense = order_offense_for('read')
    write_offense = order_offense_for('write')

    refute_nil(read_offense)
    refute_nil(write_offense)

    assert_includes(read_offense[:message], '`param`, `return`')
    assert_includes(write_offense[:message], '`param`, `example`')
  end

  it 'reports each missing separator with its own tag groups' do
    read_offense = separator_offense_for('read')
    write_offense = separator_offense_for('write')

    refute_nil(read_offense)
    refute_nil(write_offense)

    assert_includes(read_offense[:message], '`return` and `param`')
    assert_includes(write_offense[:message], '`example` and `param`')
  end

  private

  def order_offense_for(method_name)
    result.offenses.find do |o|
      o[:name] == 'InvalidTagOrder' && o[:message].include?("`#{method_name}`")
    end
  end

  def separator_offense_for(method_name)
    result.offenses.find do |o|
      o[:name] == 'MissingTagGroupSeparator' && o[:message].include?("`#{method_name}`")
    end
  end
end

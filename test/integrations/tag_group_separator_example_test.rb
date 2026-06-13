# frozen_string_literal: true

# Proves that Tags/TagGroupSeparator does not treat indented @-leading lines
# inside an @example body (e.g. an instance variable like @result) as YARD
# tag groups. Real YARD tags begin at column 0 of the docstring; the scanner
# stripped each line before checking for a leading @, so example/code content
# created phantom one-tag groups and spurious missing-separator offenses.
describe 'TagGroupSeparator example bodies' do
  attr_reader :result

  before do
    fixture_path = File.expand_path('../fixtures/tag_group_separator_example.rb', __dir__)
    config = test_config do |c|
      c.set_validator_config('Tags/TagGroupSeparator', 'Enabled', true)
    end
    @result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
  end

  it 'does not flag an instance variable inside an @example body as a tag group' do
    offenses = result.offenses.select do |o|
      o[:name] == 'MissingTagGroupSeparator' && o[:message].include?('perform')
    end

    assert_empty(offenses, 'indented @ivar inside @example body was treated as a tag')
  end

  it 'still detects a genuinely missing separator between real tag groups' do
    offenses = result.offenses.select do |o|
      o[:name] == 'MissingTagGroupSeparator' && o[:message].include?('joined')
    end

    refute_empty(offenses)
  end
end

# frozen_string_literal: true

# Proves that Tags/Order and Tags/TagGroupSeparator check class and module
# docstrings. Both validators called object.is_alias? before checking the
# object type; on namespace objects YARD's method_missing raises NameError
# (not NoMethodError), which the query executor swallows, so every class,
# module, and constant used to be silently skipped by these validators.
describe 'Namespace tag offenses' do
  attr_reader :fixture_path, :result

  before do
    @fixture_path = File.expand_path('../fixtures/namespace_tag_offenses.rb', __dir__)
    config = test_config do |c|
      c.set_validator_config('Tags/TagGroupSeparator', 'Enabled', true)
    end
    @result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
  end

  it 'reports wrong tag order on a class docstring' do
    offenses = result.offenses.select do |o|
      o[:name] == 'InvalidTagOrder' &&
        o[:message].include?('ClassWithWrongTagOrder')
    end

    refute_empty(offenses, 'class docstrings were silently skipped by Tags/Order')

    assert_includes(offenses.first[:message], '`example`, `note`')
  end

  it 'does not report classes with valid tag order' do
    offenses = result.offenses.select do |o|
      o[:name] == 'InvalidTagOrder' &&
        o[:message].include?('ClassWithValidTagOrder')
    end

    assert_empty(offenses)
  end

  it 'reports a missing tag group separator on a module docstring' do
    offenses = result.offenses.select do |o|
      o[:name] == 'MissingTagGroupSeparator' &&
        o[:message].include?('ModuleWithJoinedTagGroups')
    end

    refute_empty(offenses, 'module docstrings were silently skipped by Tags/TagGroupSeparator')

    assert_includes(offenses.first[:message], '`meta` and `example`')
  end
end

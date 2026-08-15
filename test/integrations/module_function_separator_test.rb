# frozen_string_literal: true

# Proves that Tags/TagSeparator does not report a method just because
# module_function made YARD register it twice. The copy YARD builds with
# Docstring#to_raw has every blank line between tags stripped, so linting it
# reports a layout offense against text no one wrote. A genuinely unseparated
# module_function method must still be reported, exactly once.
describe 'TagSeparator with module_function' do
  attr_reader :result

  def offenses_for(method_name)
    result.offenses.select do |offense|
      offense[:name] == 'MissingTagSeparator' && offense[:method_name] == method_name
    end
  end

  before do
    fixture_path = File.expand_path('../fixtures/module_function_example.rb', __dir__)
    config = test_config do |c|
      c.set_validator_config('Tags/TagSeparator', 'Enabled', true)
      c.set_validator_config('Tags/TagSeparator', 'RequireAfterDescription', true)
    end
    @result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
  end

  it 'does not flag a separated method defined under a bare module_function' do
    assert_empty(offenses_for('bare_separated'))
  end

  it 'does not flag a separated method passed to module_function by symbol' do
    assert_empty(offenses_for('symbol_separated'))
  end

  it 'does not flag a separated method defined with module_function def' do
    assert_empty(offenses_for('decorator_separated'))
  end

  it 'still flags a genuinely unseparated module_function method once' do
    offenses = offenses_for('bare_unseparated')

    assert_equal(1, offenses.size)
    assert_includes(offenses.first[:message], 'param')
  end
end

# The same duplicate registration reaches Tags/TagGroupSeparator, which judges
# the same reconstructed layout.
describe 'TagGroupSeparator with module_function' do
  attr_reader :result

  def offenses_for(method_name)
    result.offenses.select do |offense|
      offense[:name] == 'MissingTagGroupSeparator' && offense[:method_name] == method_name
    end
  end

  before do
    fixture_path = File.expand_path('../fixtures/module_function_example.rb', __dir__)
    config = test_config do |c|
      c.set_validator_config('Tags/TagGroupSeparator', 'Enabled', true)
    end
    @result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
  end

  it 'does not flag a separated method defined under a bare module_function' do
    assert_empty(offenses_for('bare_separated'))
  end

  it 'does not flag a separated method passed to module_function by symbol' do
    assert_empty(offenses_for('symbol_separated'))
  end

  it 'does not flag a separated method defined with module_function def' do
    assert_empty(offenses_for('decorator_separated'))
  end

  it 'still flags a genuinely unseparated module_function method once' do
    assert_equal(1, offenses_for('bare_unseparated').size)
  end
end

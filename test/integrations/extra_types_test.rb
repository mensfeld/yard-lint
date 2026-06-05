# frozen_string_literal: true

# Integration tests for the ExtraTypes configuration option in Tags/InvalidTypes.
# ExtraTypes lets users declare non-standard type names (e.g. Solargraph's
# `generic` type-parameter notation) so that yard-lint does not report them
# as InvalidTagType offenses.
#
# Only lowercase tokens that raise NameError in Kernel.const_defined? are flagged
# by default; uppercase names like `Callable` are treated as syntactically valid
# constant names and are not flagged regardless of ExtraTypes.
describe 'Tags/InvalidTypes ExtraTypes configuration' do
  attr_reader :fixture_path

  before do
    @fixture_path = File.expand_path('../fixtures/extra_types.rb', __dir__)
  end

  # -- Without ExtraTypes: non-standard lowercase types ARE flagged --

  it 'flags generic type without ExtraTypes configured' do
    config = test_config do |c|
      c.set_validator_config('Tags/InvalidTypes', 'Enabled', true)
    end

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find { |o| o[:name] == 'InvalidTagType' && o[:message].include?('generic_types') }

    refute_nil(offense, 'generic type should be flagged when not in ExtraTypes')
    assert_includes(offense[:message], 'generic')
  end

  it 'flags standalone generic return type without ExtraTypes configured' do
    config = test_config do |c|
      c.set_validator_config('Tags/InvalidTypes', 'Enabled', true)
    end

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find { |o| o[:name] == 'InvalidTagType' && o[:message].include?('standalone_generic') }

    refute_nil(offense, 'generic<T> return type should be flagged when not in ExtraTypes')
  end

  # -- With ExtraTypes: configured types are accepted --

  it 'does not flag generic type when added to ExtraTypes' do
    config = test_config do |c|
      c.set_validator_config('Tags/InvalidTypes', 'Enabled', true)
      c.set_validator_config('Tags/InvalidTypes', 'ExtraTypes', ['generic'])
    end

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find { |o| o[:name] == 'InvalidTagType' && o[:message].include?('generic_types') }

    assert_nil(offense, 'generic should not be flagged when listed in ExtraTypes')
  end

  it 'does not flag standalone generic return type when added to ExtraTypes' do
    config = test_config do |c|
      c.set_validator_config('Tags/InvalidTypes', 'Enabled', true)
      c.set_validator_config('Tags/InvalidTypes', 'ExtraTypes', ['generic'])
    end

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find { |o| o[:name] == 'InvalidTagType' && o[:message].include?('standalone_generic') }

    assert_nil(offense, 'generic<T> return type should not be flagged when generic is in ExtraTypes')
  end

  it 'does not flag any offense when all custom types are added to ExtraTypes' do
    config = test_config do |c|
      c.set_validator_config('Tags/InvalidTypes', 'Enabled', true)
      c.set_validator_config('Tags/InvalidTypes', 'ExtraTypes', %w[generic awaitable])
    end

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offenses = result.offenses.select { |o| o[:name] == 'InvalidTagType' }

    assert_empty(offenses, "Expected no InvalidTagType offenses but got: #{offenses.map { |o| o[:message] }}")
  end

  it 'only suppresses the listed ExtraTypes and still flags others' do
    config = test_config do |c|
      c.set_validator_config('Tags/InvalidTypes', 'Enabled', true)
      # Only add generic - awaitable should still be flagged
      c.set_validator_config('Tags/InvalidTypes', 'ExtraTypes', ['generic'])
    end

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    # generic is suppressed across all methods that use it
    generic_types_offense = result.offenses.find { |o| o[:name] == 'InvalidTagType' && o[:message].include?('generic_types') }
    standalone_offense    = result.offenses.find { |o| o[:name] == 'InvalidTagType' && o[:message].include?('standalone_generic') }
    # awaitable is not in ExtraTypes - still flagged
    multiple_offense      = result.offenses.find { |o| o[:name] == 'InvalidTagType' && o[:message].include?('multiple_custom') }

    assert_nil(generic_types_offense, 'generic should not be flagged when in ExtraTypes')
    assert_nil(standalone_offense,    'standalone generic should not be flagged when in ExtraTypes')
    refute_nil(multiple_offense,      'awaitable should still be flagged when not in ExtraTypes')
    assert_includes(multiple_offense[:message], 'awaitable')
  end
end

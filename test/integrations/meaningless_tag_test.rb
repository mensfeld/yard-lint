# frozen_string_literal: true

describe 'Meaningless Tag' do
  attr_reader :fixture_path, :config

  before do
    @fixture_path = File.expand_path('../fixtures/meaningless_tag_examples.rb', __dir__)
    @config = test_config do |c|
      c.set_validator_config('Tags/MeaninglessTag', 'Enabled', true)
    end
  end

  it 'detecting meaningless tags finds param tags on classes' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    param_on_class = result.offenses.select do |o|
      o[:name] == 'MeaninglessTag' &&
        o[:message].include?('@param') &&
        o[:message].include?('class')
    end

    refute_empty(param_on_class)
  end

  it 'detecting meaningless tags finds option tags on modules' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    option_on_module = result.offenses.select do |o|
      o[:name] == 'MeaninglessTag' &&
        o[:message].include?('@option') &&
        o[:message].include?('module')
    end

    refute_empty(option_on_module)
  end

  it 'detecting meaningless tags finds param tags on constants' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    param_on_constant = result.offenses.select do |o|
      o[:name] == 'MeaninglessTag' &&
        o[:message].include?('@param') &&
        o[:message].include?('constant')
    end

    refute_empty(param_on_constant)
  end

  it 'detecting meaningless tags does not flag valid param tags on methods' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    # All offenses should be on classes/modules/constants, not methods
    offenses = result.offenses.select { |o| o[:name] == 'MeaninglessTag' }

    offenses.each do |offense|
      # Check that the offense is about a class, module, or constant (not a method)
      assert_match(/on a (class|module|constant)/, offense[:message])
    end
  end

  it 'detecting meaningless tags provides helpful error messages' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find { |o| o[:name] == 'MeaninglessTag' }
    refute_nil(offense)
    assert_includes(offense[:message], 'meaningless')
    assert_includes(offense[:message], 'only makes sense on methods')
  end

  it 'when disabled does not run validation' do
    disabled_config = test_config do |c|
      c.set_validator_config('Tags/MeaninglessTag', 'Enabled', false)
    end

    result = Yard::Lint.run(path: fixture_path, config: disabled_config, progress: false)

    meaningless_tag_offenses = result.offenses.select { |o| o[:name] == 'MeaninglessTag' }
    assert_empty(meaningless_tag_offenses)
  end
end


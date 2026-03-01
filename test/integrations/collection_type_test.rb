# frozen_string_literal: true

require 'test_helper'


describe 'Collection Type' do
  attr_reader :fixture_path, :config


  before do
    @fixture_path = File.expand_path('../fixtures/collection_type_examples.rb', __dir__)
    @config = test_config do |c|
      c.set_validator_config('Tags/CollectionType', 'Enabled', true)
    end
  end

  it 'detecting incorrect hash syntax finds hash k v in param tags' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    hash_in_param = result.offenses.select do |o|
      o[:name] == 'CollectionType' &&
        o[:message].include?('Hash<Symbol, String>')
    end

    refute_empty(hash_in_param)
  end

  it 'detecting incorrect hash syntax finds nested hash syntax' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    nested_hash = result.offenses.select do |o|
      o[:name] == 'CollectionType' &&
        o[:message].include?('Hash<String, Hash<Symbol')
    end

    refute_empty(nested_hash)
  end

  it 'detecting incorrect hash syntax finds hash in return tags' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    hash_in_return = result.offenses.select do |o|
      o[:name] == 'CollectionType' &&
        o[:message].include?('@return')
    end

    refute_empty(hash_in_return)
  end

  it 'detecting incorrect hash syntax does not flag hash curly syntax' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    # All offenses should be about Hash<>, not Hash{}
    offenses = result.offenses.select { |o| o[:name] == 'CollectionType' }

    offenses.each do |offense|
      assert_includes(offense[:message], 'Hash<')
      assert_includes(offense[:message], 'Hash{')
    end
  end

  it 'detecting incorrect hash syntax does not flag array syntax' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    # Should not have violations for Array<String>
    array_violations = result.offenses.select do |o|
      o[:name] == 'CollectionType' &&
        o[:message].include?('Array<')
    end

    assert_empty(array_violations)
  end

  it 'detecting incorrect hash syntax provides helpful error messages' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find { |o| o[:name] == 'CollectionType' }
    refute_nil(offense)
    assert_includes(offense[:message], 'Hash{')
    assert_includes(offense[:message], '=>')
    assert_includes(offense[:message], 'long collection syntax')
  end

  it 'when enforcing short style finds hash k v in param tags' do
    short_style_config = test_config do |c|
      c.set_validator_config('Tags/CollectionType', 'Enabled', true)
      c.set_validator_config('Tags/CollectionType', 'EnforcedStyle', 'short')
    end

    result = Yard::Lint.run(path: fixture_path, config: short_style_config, progress: false)

    hash_violations = result.offenses.select do |o|
      o[:name] == 'CollectionType' &&
        o[:message].include?('Hash{Symbol => String}')
    end

    refute_empty(hash_violations)
  end

  it 'when enforcing short style suggests removing hash prefix' do
    short_style_config = test_config do |c|
      c.set_validator_config('Tags/CollectionType', 'Enabled', true)
      c.set_validator_config('Tags/CollectionType', 'EnforcedStyle', 'short')
    end

    result = Yard::Lint.run(path: fixture_path, config: short_style_config, progress: false)

    offense = result.offenses.find { |o| o[:name] == 'CollectionType' }
    refute_nil(offense)
    assert_includes(offense[:message], 'short collection syntax')
    assert_includes(offense[:message], '{')
    assert_includes(offense[:message], '=>')
  end

  it 'when enforcing short style does not flag hash angle syntax' do
    short_style_config = test_config do |c|
      c.set_validator_config('Tags/CollectionType', 'Enabled', true)
      c.set_validator_config('Tags/CollectionType', 'EnforcedStyle', 'short')
    end

    result = Yard::Lint.run(path: fixture_path, config: short_style_config, progress: false)

    # Should not have violations for Hash<K, V> when enforcing short
    offenses = result.offenses.select { |o| o[:name] == 'CollectionType' }

    offenses.each do |offense|
      refute_includes(offense[:message], 'Hash<')
    end
  end

  it 'when enforcing short style does not flag k v syntax' do
    short_style_config = test_config do |c|
      c.set_validator_config('Tags/CollectionType', 'Enabled', true)
      c.set_validator_config('Tags/CollectionType', 'EnforcedStyle', 'short')
    end

    result = Yard::Lint.run(path: fixture_path, config: short_style_config, progress: false)

    # Should only have violations for Hash{K => V}, not {K => V}
    offenses = result.offenses.select { |o| o[:name] == 'CollectionType' }

    offenses.each do |offense|
      # The type_string in the message should be Hash{...}
      assert_includes(offense[:message], 'instead of Hash{')
    end
  end

  it 'when disabled does not run validation' do
    disabled_config = test_config do |c|
      c.set_validator_config('Tags/CollectionType', 'Enabled', false)
    end

    result = Yard::Lint.run(path: fixture_path, config: disabled_config, progress: false)

    collection_type_offenses = result.offenses.select { |o| o[:name] == 'CollectionType' }
    assert_empty(collection_type_offenses)
  end
end

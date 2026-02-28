# frozen_string_literal: true

require 'test_helper'

class CollectionTypeIntegrationTest < Minitest::Test
  attr_reader :config, :fixture_path

  def setup
    @fixture_path = File.expand_path('../fixtures/collection_type_examples.rb', __dir__)
    @config = test_config do |c|
      c.send(:set_validator_config, 'Tags/CollectionType', 'Enabled', true)
    end
  end

  def test_detecting_incorrect_hash_syntax_finds_hash_k_v_in_param_tags
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    hash_in_param = result.offenses.select do |o|
      o[:name] == 'CollectionType' &&
        o[:message].include?('Hash<Symbol, String>')
    end

    refute_empty(hash_in_param)
  end

  def test_detecting_incorrect_hash_syntax_finds_nested_hash_syntax
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    nested_hash = result.offenses.select do |o|
      o[:name] == 'CollectionType' &&
        o[:message].include?('Hash<String, Hash<Symbol')
    end

    refute_empty(nested_hash)
  end

  def test_detecting_incorrect_hash_syntax_finds_hash_in_return_tags
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    hash_in_return = result.offenses.select do |o|
      o[:name] == 'CollectionType' &&
        o[:message].include?('@return')
    end

    refute_empty(hash_in_return)
  end

  def test_detecting_incorrect_hash_syntax_does_not_flag_hash_curly_syntax
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    # All offenses should be about Hash<>, not Hash{}
    offenses = result.offenses.select { |o| o[:name] == 'CollectionType' }

    offenses.each do |offense|
      assert_includes(offense[:message], 'Hash<')
      assert_includes(offense[:message], 'Hash{')
    end
  end

  def test_detecting_incorrect_hash_syntax_does_not_flag_array_syntax
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    # Should not have violations for Array<String>
    array_violations = result.offenses.select do |o|
      o[:name] == 'CollectionType' &&
        o[:message].include?('Array<')
    end

    assert_empty(array_violations)
  end

  def test_detecting_incorrect_hash_syntax_provides_helpful_error_messages
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find { |o| o[:name] == 'CollectionType' }
    refute_nil(offense)
    assert_includes(offense[:message], 'Hash{')
    assert_includes(offense[:message], '=>')
    assert_includes(offense[:message], 'long collection syntax')
  end

  def test_when_enforcing_short_style_finds_hash_k_v_in_param_tags
    short_style_config = test_config do |c|
      c.send(:set_validator_config, 'Tags/CollectionType', 'Enabled', true)
      c.send(:set_validator_config, 'Tags/CollectionType', 'EnforcedStyle', 'short')
    end

    result = Yard::Lint.run(path: fixture_path, config: short_style_config, progress: false)

    hash_violations = result.offenses.select do |o|
      o[:name] == 'CollectionType' &&
        o[:message].include?('Hash{Symbol => String}')
    end

    refute_empty(hash_violations)
  end

  def test_when_enforcing_short_style_suggests_removing_hash_prefix
    short_style_config = test_config do |c|
      c.send(:set_validator_config, 'Tags/CollectionType', 'Enabled', true)
      c.send(:set_validator_config, 'Tags/CollectionType', 'EnforcedStyle', 'short')
    end

    result = Yard::Lint.run(path: fixture_path, config: short_style_config, progress: false)

    offense = result.offenses.find { |o| o[:name] == 'CollectionType' }
    refute_nil(offense)
    assert_includes(offense[:message], 'short collection syntax')
    assert_includes(offense[:message], '{')
    assert_includes(offense[:message], '=>')
  end

  def test_when_enforcing_short_style_does_not_flag_hash_angle_syntax
    short_style_config = test_config do |c|
      c.send(:set_validator_config, 'Tags/CollectionType', 'Enabled', true)
      c.send(:set_validator_config, 'Tags/CollectionType', 'EnforcedStyle', 'short')
    end

    result = Yard::Lint.run(path: fixture_path, config: short_style_config, progress: false)

    # Should not have violations for Hash<K, V> when enforcing short
    offenses = result.offenses.select { |o| o[:name] == 'CollectionType' }

    offenses.each do |offense|
      refute_includes(offense[:message], 'Hash<')
    end
  end

  def test_when_enforcing_short_style_does_not_flag_k_v_syntax
    short_style_config = test_config do |c|
      c.send(:set_validator_config, 'Tags/CollectionType', 'Enabled', true)
      c.send(:set_validator_config, 'Tags/CollectionType', 'EnforcedStyle', 'short')
    end

    result = Yard::Lint.run(path: fixture_path, config: short_style_config, progress: false)

    # Should only have violations for Hash{K => V}, not {K => V}
    offenses = result.offenses.select { |o| o[:name] == 'CollectionType' }

    offenses.each do |offense|
      # The type_string in the message should be Hash{...}
      assert_includes(offense[:message], 'instead of Hash{')
    end
  end

  def test_when_disabled_does_not_run_validation
    disabled_config = test_config do |c|
      c.send(:set_validator_config, 'Tags/CollectionType', 'Enabled', false)
    end

    result = Yard::Lint.run(path: fixture_path, config: disabled_config, progress: false)

    collection_type_offenses = result.offenses.select { |o| o[:name] == 'CollectionType' }
    assert_empty(collection_type_offenses)
  end
end

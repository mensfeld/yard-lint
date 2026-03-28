# frozen_string_literal: true

# Regression test for https://github.com/mensfeld/yard-lint/issues/114
# CollectionType validator should enforce style for Array types, not just Hash.
# YARD supports both long and short forms:
#   Long:  Array<String>, Array(String, Integer)
#   Short: <String>, (String, Integer)
describe 'Array Collection Type' do
  attr_reader :fixture_path

  before do
    @fixture_path = File.expand_path('../fixtures/array_collection_type_examples.rb', __dir__)
  end

  describe 'when enforcing long style (default)' do
    attr_reader :config

    before do
      @config = test_config do |c|
        c.set_validator_config('Tags/CollectionType', 'Enabled', true)
        c.set_validator_config('Tags/CollectionType', 'EnforcedStyle', 'long')
      end
    end

    # --- Should NOT flag long style types ---

    it 'does not flag Array<String> in @param' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' && o[:type_string] == 'Array<String>'
      end

      assert_nil(offense, 'Array<String> is long style and should not be flagged')
    end

    it 'does not flag Array<Integer> in @return' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' && o[:type_string] == 'Array<Integer>'
      end

      assert_nil(offense, 'Array<Integer> is long style and should not be flagged')
    end

    it 'does not flag Array<Array<Integer>> (nested)' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' && o[:type_string] == 'Array<Array<Integer>>'
      end

      assert_nil(offense, 'Nested Array<Array<Integer>> is long style and should not be flagged')
    end

    it 'does not flag Array(String, Integer) in @param' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' && o[:type_string] == 'Array(String, Integer)'
      end

      assert_nil(offense, 'Array(String, Integer) is long style and should not be flagged')
    end

    it 'does not flag Array(Symbol, String, Integer) in @return' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' && o[:type_string] == 'Array(Symbol, String, Integer)'
      end

      assert_nil(offense, 'Array(Symbol, String, Integer) is long style and should not be flagged')
    end

    it 'does not flag Array(Boolean, String, Integer, Float) (four elements)' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' && o[:type_string] == 'Array(Boolean, String, Integer, Float)'
      end

      assert_nil(offense, 'Four-element long tuple should not be flagged')
    end

    it 'does not flag Array(String, nil) with nil element' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' && o[:type_string] == 'Array(String, nil)'
      end

      assert_nil(offense, 'Array(String, nil) is long style and should not be flagged')
    end

    it 'does not flag Array(String, Integer) when paired with nil' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' &&
          o[:type_string] == 'Array(String, Integer)' &&
          o[:object_name]&.include?('ArrayLongTupleOrNil')
      end

      assert_nil(offense, 'Long tuple or nil should not be flagged')
    end

    it 'does not flag long style in @yieldreturn tags' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' &&
          o[:object_name]&.include?('ArrayInYieldreturn') &&
          o[:type_string]&.start_with?('Array')
      end

      assert_nil(offense, 'Long style Array types in @yieldreturn should not be flagged')
    end

    # --- Should flag short style types ---

    it 'flags <String> in @param as short style' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' && o[:type_string] == '<String>'
      end

      refute_nil(offense, '<String> is short style and should be flagged when enforcing long')
      assert_includes(offense[:message], 'Array<String>')
    end

    it 'flags <Integer> in @return as short style' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' && o[:type_string] == '<Integer>'
      end

      refute_nil(offense, '<Integer> is short style and should be flagged when enforcing long')
      assert_includes(offense[:message], 'Array<Integer>')
    end

    it 'flags <String, Symbol> with multiple types as short style' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' && o[:type_string] == '<String, Symbol>'
      end

      refute_nil(offense, '<String, Symbol> is short style and should be flagged when enforcing long')
    end

    it 'flags (String, Integer) in @param as short style' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' && o[:type_string] == '(String, Integer)'
      end

      refute_nil(offense, '(String, Integer) is short style and should be flagged when enforcing long')
      assert_includes(offense[:message], 'Array(String, Integer)')
    end

    it 'flags (Symbol, String, Integer) in @return as short style' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' && o[:type_string] == '(Symbol, String, Integer)'
      end

      refute_nil(offense, '(Symbol, String, Integer) is short style and should be flagged when enforcing long')
      assert_includes(offense[:message], 'Array(Symbol, String, Integer)')
    end

    it 'flags (Boolean, String) in @return as short style' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' && o[:type_string] == '(Boolean, String)'
      end

      refute_nil(offense, '(Boolean, String) is short style and should be flagged')
    end

    it 'flags (String, Integer, Symbol, Boolean) four-element tuple as short style' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' && o[:type_string] == '(String, Integer, Symbol, Boolean)'
      end

      refute_nil(offense, 'Four-element short tuple should be flagged when enforcing long')
    end

    it 'flags (String, Integer) when paired with nil as short style' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' &&
          o[:type_string] == '(String, Integer)' &&
          o[:object_name]&.include?('ArrayShortTupleOrNil')
      end

      refute_nil(offense, 'Short tuple or nil should be flagged when enforcing long')
    end

    it 'flags short style <String> in @yieldreturn tags' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' &&
          o[:tag_name] == 'yieldreturn' &&
          o[:type_string] == '<String>'
      end

      refute_nil(offense, 'Short style <String> in @yieldreturn should be flagged')
    end

    it 'flags short style (String, Integer) in @yieldreturn tags' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' &&
          o[:tag_name] == 'yieldreturn' &&
          o[:type_string] == '(String, Integer)'
      end

      refute_nil(offense, 'Short style (String, Integer) in @yieldreturn should be flagged')
    end

    it 'suggests correct long form in error message for angle brackets' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' && o[:type_string] == '<String>'
      end

      refute_nil(offense)
      assert_includes(offense[:message], 'long collection syntax Array<String>')
      assert_includes(offense[:message], 'instead of <String>')
    end

    it 'suggests correct long form in error message for tuples' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' && o[:type_string] == '(String, Integer)'
      end

      refute_nil(offense)
      assert_includes(offense[:message], 'long collection syntax Array(String, Integer)')
      assert_includes(offense[:message], 'instead of (String, Integer)')
    end
  end

  describe 'when enforcing short style' do
    attr_reader :config

    before do
      @config = test_config do |c|
        c.set_validator_config('Tags/CollectionType', 'Enabled', true)
        c.set_validator_config('Tags/CollectionType', 'EnforcedStyle', 'short')
      end
    end

    # --- Should flag long style types ---

    it 'flags Array<String> in @param as long style' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' && o[:type_string] == 'Array<String>'
      end

      refute_nil(offense, 'Array<String> is long style and should be flagged when enforcing short')
      assert_includes(offense[:message], '<String>')
    end

    it 'flags Array<Integer> in @return as long style' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' && o[:type_string] == 'Array<Integer>'
      end

      refute_nil(offense, 'Array<Integer> is long style and should be flagged when enforcing short')
    end

    it 'flags Array<Boolean> in @return as long style' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' && o[:type_string] == 'Array<Boolean>'
      end

      refute_nil(offense, 'Array<Boolean> is long style and should be flagged when enforcing short')
    end

    it 'flags Array(String, Integer) in @param as long style' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' && o[:type_string] == 'Array(String, Integer)'
      end

      refute_nil(offense, 'Array(String, Integer) is long style and should be flagged when enforcing short')
      assert_includes(offense[:message], '(String, Integer)')
    end

    it 'flags Array(Symbol, String, Integer) in @return as long style' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' && o[:type_string] == 'Array(Symbol, String, Integer)'
      end

      refute_nil(offense, 'Array(Symbol, String, Integer) is long style and should be flagged')
    end

    it 'flags Array(Boolean, String, Integer, Float) four-element tuple as long style' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' && o[:type_string] == 'Array(Boolean, String, Integer, Float)'
      end

      refute_nil(offense, 'Four-element long tuple should be flagged when enforcing short')
    end

    it 'flags Array(String, nil) with nil element as long style' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' && o[:type_string] == 'Array(String, nil)'
      end

      refute_nil(offense, 'Array(String, nil) is long style and should be flagged')
    end

    it 'flags long style Array<String> in @yieldreturn tags' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' &&
          o[:tag_name] == 'yieldreturn' &&
          o[:type_string] == 'Array<String>'
      end

      refute_nil(offense, 'Long style Array<String> in @yieldreturn should be flagged')
    end

    it 'flags long style Array(String, Integer) in @yieldreturn tags' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' &&
          o[:tag_name] == 'yieldreturn' &&
          o[:type_string] == 'Array(String, Integer)'
      end

      refute_nil(offense, 'Long style Array(String, Integer) in @yieldreturn should be flagged')
    end

    # --- Should NOT flag short style types ---

    it 'does not flag <String> in @param' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' && o[:type_string] == '<String>'
      end

      assert_nil(offense, '<String> is short style and should not be flagged')
    end

    it 'does not flag <Integer> in @return' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' && o[:type_string] == '<Integer>'
      end

      assert_nil(offense, '<Integer> is short style and should not be flagged')
    end

    it 'does not flag (String, Integer) in @param' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' && o[:type_string] == '(String, Integer)'
      end

      assert_nil(offense, '(String, Integer) is short style and should not be flagged')
    end

    it 'does not flag (Symbol, String, Integer) in @return' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' && o[:type_string] == '(Symbol, String, Integer)'
      end

      assert_nil(offense, '(Symbol, String, Integer) is short style and should not be flagged')
    end

    it 'does not flag short style in @yieldreturn tags' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' &&
          o[:tag_name] == 'yieldreturn' &&
          !o[:type_string]&.start_with?('Array')
      end

      assert_nil(offense, 'Short style Array types in @yieldreturn should not be flagged')
    end

    it 'suggests correct short form in error message for angle brackets' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' && o[:type_string] == 'Array<String>'
      end

      refute_nil(offense)
      assert_includes(offense[:message], 'short collection syntax <String>')
      assert_includes(offense[:message], 'instead of Array<String>')
    end

    it 'suggests correct short form in error message for tuples' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' && o[:type_string] == 'Array(String, Integer)'
      end

      refute_nil(offense)
      assert_includes(offense[:message], 'short collection syntax (String, Integer)')
      assert_includes(offense[:message], 'instead of Array(String, Integer)')
    end
  end

  describe 'does not interfere with Hash types' do
    it 'does not flag Hash{Symbol => String} when enforcing long style' do
      config = test_config do |c|
        c.set_validator_config('Tags/CollectionType', 'Enabled', true)
        c.set_validator_config('Tags/CollectionType', 'EnforcedStyle', 'long')
      end

      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      # This fixture uses Hash{} which is long style - should not be flagged
      hash_offense = result.offenses.find do |o|
        o[:name] == 'CollectionType' && o[:type_string]&.include?('Hash')
      end

      assert_nil(hash_offense, 'Hash{Symbol => String} is long style and should not be flagged')
    end
  end
end

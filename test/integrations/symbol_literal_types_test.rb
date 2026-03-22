# frozen_string_literal: true

# Regression test for https://github.com/mensfeld/yard-lint/issues/109
# Symbol and string literals are valid YARD type notations but were incorrectly
# flagged as InvalidTypeSyntax by the TypeSyntax validator.
describe 'Symbol Literal Types' do
  attr_reader :fixture_path, :config

  before do
    @fixture_path = File.expand_path('../fixtures/symbol_literal_types.rb', __dir__)
    @config = test_config do |c|
      c.set_validator_config('Tags/TypeSyntax', 'Enabled', true)
    end
  end

  it 'does not produce any InvalidTypeSyntax offenses for the fixture' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    type_syntax_offenses = result.offenses.select { |o| o[:name] == 'InvalidTypeSyntax' }

    assert_empty(
      type_syntax_offenses,
      "Expected no InvalidTypeSyntax offenses but got: #{type_syntax_offenses.map { |o| o[:message] }}"
    )
  end

  describe 'simple symbol literals' do
    it 'accepts symbol literals in @return tags' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?(':ok')
      end

      assert_nil(offense, "Symbol literal ':ok' in @return should not be flagged")
    end

    it 'accepts symbol literals in @param tags' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?(':debug')
      end

      assert_nil(offense, "Symbol literal ':debug' in @param should not be flagged")
    end

    it 'accepts symbol literals appearing in both @param and @return on same method' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?(':asc')
      end

      assert_nil(offense, "Symbol literal ':asc' should not be flagged")
    end

    it 'accepts a single symbol literal as only type' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?(':singleton')
      end

      assert_nil(offense, "Single symbol literal ':singleton' should not be flagged")
    end
  end

  describe 'symbols with underscores and numbers' do
    it 'accepts symbol literals containing underscores and digits' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?(':foo_bar')
      end

      assert_nil(offense, "Symbol literal ':foo_bar' should not be flagged")
    end
  end

  describe 'predicate, bang, and setter symbols' do
    it 'accepts predicate symbol literals ending with ?' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?(':empty?')
      end

      assert_nil(offense, "Predicate symbol ':empty?' should not be flagged")
    end

    it 'accepts bang symbol literals ending with !' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?(':save!')
      end

      assert_nil(offense, "Bang symbol ':save!' should not be flagged")
    end

    it 'accepts setter symbol literals ending with =' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?(':name=')
      end

      assert_nil(offense, "Setter symbol ':name=' should not be flagged")
    end
  end

  describe 'quoted symbol literals' do
    it 'accepts double-quoted symbol literals with special characters' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?(':"content-type"')
      end

      assert_nil(offense, 'Double-quoted symbol :"content-type" should not be flagged')
    end

    it 'accepts single-quoted symbol literals with special characters' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?(":'content-type'")
      end

      assert_nil(offense, "Single-quoted symbol :'content-type' should not be flagged")
    end
  end

  describe 'string literals' do
    it 'accepts string literals in @param tags' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?('"read"')
      end

      assert_nil(offense, 'String literal "read" in @param should not be flagged')
    end

    it 'accepts string literals in @return tags' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?('"success"')
      end

      assert_nil(offense, 'String literal "success" in @return should not be flagged')
    end

    it 'accepts string literals containing special characters' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?('"."')
      end

      assert_nil(offense, 'String literal "." should not be flagged')
    end
  end

  describe 'empty string literals' do
    it 'accepts empty double-quoted string literals' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?('""')
      end

      assert_nil(offense, 'Empty double-quoted string "" should not be flagged')
    end

    it 'accepts empty single-quoted string literals' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?("''")
      end

      assert_nil(offense, "Empty single-quoted string '' should not be flagged")
    end
  end

  describe 'single-quoted string literals' do
    it 'accepts single-quoted string literals in @param tags' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?("'read'")
      end

      assert_nil(offense, "Single-quoted string literal 'read' in @param should not be flagged")
    end

    it 'accepts single-quoted string literals in @return tags' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?("'success'")
      end

      assert_nil(offense, "Single-quoted string literal 'success' in @return should not be flagged")
    end

    it 'accepts single-quoted string literals containing special characters' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?("'.'")
      end

      assert_nil(offense, "Single-quoted string literal '.' should not be flagged")
    end
  end

  describe 'numeric literals' do
    it 'accepts integer literals' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:type_string] == '0'
      end

      assert_nil(offense, 'Integer literal 0 should not be flagged')
    end

    it 'accepts negative integer literals' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?('-1')
      end

      assert_nil(offense, 'Negative integer literal -1 should not be flagged')
    end

    it 'accepts float literals' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?('2.5')
      end

      assert_nil(offense, 'Float literal 2.5 should not be flagged')
    end

    it 'accepts negative float literals' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?('-0.5')
      end

      assert_nil(offense, 'Negative float literal -0.5 should not be flagged')
    end
  end

  describe 'all literal types mixed' do
    it 'accepts integers, floats, strings, symbols, and nil mixed together' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?('all_literal_types_mixed')
      end

      assert_nil(offense, 'Mixed literal types (int, float, string, symbol, nil) should not be flagged')
    end
  end

  describe 'mixed literals with regular types' do
    it 'accepts symbol literals mixed with class types' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?(':text')
      end

      assert_nil(offense, "Symbol ':text' mixed with Symbol class should not be flagged")
    end

    it 'accepts string literals mixed with class types' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?('"on"')
      end

      assert_nil(offense, 'String "on" mixed with Boolean class should not be flagged')
    end

    it 'accepts symbol and string literals mixed with nil' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?('"error"')
      end

      assert_nil(offense, 'Mixed symbol/string/nil types should not be flagged')
    end
  end

  describe 'literals in @option tags' do
    it 'accepts symbol literals in @option tags' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?(':asc') &&
          o[:message].include?('@option')
      end

      assert_nil(offense, "Symbol literal ':asc' in @option should not be flagged")
    end

    it 'accepts string literals in @option tags' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?('"csv"') &&
          o[:message].include?('@option')
      end

      assert_nil(offense, 'String literal "csv" in @option should not be flagged')
    end
  end

  describe 'literals in @yieldreturn tags' do
    it 'accepts symbol literals in @yieldreturn tags' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?(':success') &&
          o[:message].include?('@yieldreturn')
      end

      assert_nil(offense, "Symbol literal ':success' in @yieldreturn should not be flagged")
    end

    it 'accepts string literals in @yieldreturn tags' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?('"done"') &&
          o[:message].include?('@yieldreturn')
      end

      assert_nil(offense, 'String literal "done" in @yieldreturn should not be flagged')
    end
  end

  describe 'multiple params with literals' do
    it 'accepts many symbol-only params on a single method' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?(':active')
      end

      assert_nil(offense, 'Multiple symbol-only params should not be flagged')
    end

    it 'accepts many string-only params on a single method' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?('"DEBUG"')
      end

      assert_nil(offense, 'Multiple string-only params should not be flagged')
    end
  end
end

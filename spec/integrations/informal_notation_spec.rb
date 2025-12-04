# frozen_string_literal: true

RSpec.describe 'InformalNotation Integration' do
  let(:fixture_path) { File.expand_path('../fixtures/informal_notation_examples.rb', __dir__) }

  let(:config) do
    test_config do |c|
      c.send(:set_validator_config, 'Tags/InformalNotation', 'Enabled', true)
    end
  end

  describe 'detecting informal notation patterns' do
    it 'finds Note: patterns' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      note_offenses = result.offenses.select do |o|
        o[:name] == 'InformalNotation' &&
          o[:message].include?("'Note:'")
      end

      expect(note_offenses).not_to be_empty
      expect(note_offenses.first[:message]).to include('@note')
    end

    it 'finds TODO: patterns' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      todo_offenses = result.offenses.select do |o|
        o[:name] == 'InformalNotation' &&
          o[:message].include?("'Todo:'")
      end

      expect(todo_offenses).not_to be_empty
      expect(todo_offenses.first[:message]).to include('@todo')
    end

    it 'finds See: patterns' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      see_offenses = result.offenses.select do |o|
        o[:name] == 'InformalNotation' &&
          o[:message].include?("'See:'")
      end

      expect(see_offenses).not_to be_empty
      expect(see_offenses.first[:message]).to include('@see')
    end

    it 'finds Warning: patterns' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      warning_offenses = result.offenses.select do |o|
        o[:name] == 'InformalNotation' &&
          o[:message].include?("'Warning:'")
      end

      expect(warning_offenses).not_to be_empty
      expect(warning_offenses.first[:message]).to include('@deprecated')
    end

    it 'finds Deprecated: patterns' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      deprecated_offenses = result.offenses.select do |o|
        o[:name] == 'InformalNotation' &&
          o[:message].include?("'Deprecated:'")
      end

      expect(deprecated_offenses).not_to be_empty
      expect(deprecated_offenses.first[:message]).to include('@deprecated')
    end

    it 'finds FIXME: patterns' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      fixme_offenses = result.offenses.select do |o|
        o[:name] == 'InformalNotation' &&
          o[:message].include?("'FIXME:'")
      end

      expect(fixme_offenses).not_to be_empty
      expect(fixme_offenses.first[:message]).to include('@todo')
    end

    it 'finds IMPORTANT: patterns' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      important_offenses = result.offenses.select do |o|
        o[:name] == 'InformalNotation' &&
          o[:message].include?("'IMPORTANT:'")
      end

      expect(important_offenses).not_to be_empty
      expect(important_offenses.first[:message]).to include('@note')
    end

    it 'does not flag patterns inside code blocks' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      # The with_code_block method has patterns inside ```, should not be flagged
      code_block_method_offenses = result.offenses.select do |o|
        o[:name] == 'InformalNotation' &&
          o[:message].include?('inside a code block')
      end

      expect(code_block_method_offenses).to be_empty
    end

    it 'does not flag proper YARD tags' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      # Methods with proper @note and @todo tags should not be flagged for those
      offenses = result.offenses.select { |o| o[:name] == 'InformalNotation' }

      # None of the offenses should be about proper YARD tag syntax
      offenses.each do |offense|
        expect(offense[:message]).not_to include('@note This is a proper')
        expect(offense[:message]).not_to include('@todo This is a proper')
      end
    end
  end

  describe 'when disabled' do
    let(:config) do
      test_config do |c|
        c.send(:set_validator_config, 'Tags/InformalNotation', 'Enabled', false)
      end
    end

    it 'does not run validation' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      informal_notation_offenses = result.offenses.select { |o| o[:name] == 'InformalNotation' }
      expect(informal_notation_offenses).to be_empty
    end
  end

  describe 'case sensitivity configuration' do
    let(:config) do
      test_config do |c|
        c.send(:set_validator_config, 'Tags/InformalNotation', 'Enabled', true)
        c.send(:set_validator_config, 'Tags/InformalNotation', 'CaseSensitive', false)
      end
    end

    it 'matches patterns case-insensitively by default' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      # Should find patterns regardless of case
      offenses = result.offenses.select { |o| o[:name] == 'InformalNotation' }
      expect(offenses).not_to be_empty
    end
  end
end

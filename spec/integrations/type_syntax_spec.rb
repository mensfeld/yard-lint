# frozen_string_literal: true

RSpec.describe 'Type Syntax Validation Integration' do
  let(:fixture_path) { File.expand_path('../fixtures/type_syntax_examples.rb', __dir__) }
  let(:config) do
    test_config do |c|
      c.send(:set_validator_config, 'Tags/TypeSyntax', 'Enabled', true)
    end
  end

  describe 'detecting type syntax errors' do
    it 'detects unclosed bracket in @param tag' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?('Array<')
      end

      expect(offense).not_to be_nil
      expect(offense[:location]).to eq(fixture_path)
      expect(offense[:severity]).to eq('warning')
      expect(offense[:message]).to include('Invalid type syntax')
      expect(offense[:message]).to include('@param')
    end

    it 'detects empty generic in @return tag' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?('Array<>')
      end

      expect(offense).not_to be_nil
      expect(offense[:message]).to include('@return')
    end

    it 'detects unclosed hash syntax' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?('Hash{Symbol =>')
      end

      expect(offense).not_to be_nil
      expect(offense[:message]).to include('Invalid type syntax')
    end

    it 'detects malformed hash syntax' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?('Hash{Symbol]')
      end

      expect(offense).not_to be_nil
    end

    it 'does not flag valid type syntax' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      # Should not flag valid_types method
      valid_offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?('valid_types')
      end

      expect(valid_offense).to be_nil
    end

    it 'does not flag multiple types (union syntax)' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      # Should not flag multiple_types method
      union_offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?('String, Integer')
      end

      expect(union_offense).to be_nil
    end

    it 'does not flag nested generics' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      # Should not flag nested_generics method
      nested_offense = result.offenses.find do |o|
        o[:name] == 'InvalidTypeSyntax' && o[:message].include?('Array<Array<Integer>>')
      end

      expect(nested_offense).to be_nil
    end
  end

  describe 'validator configuration' do
    context 'when TypeSyntax validator is disabled' do
      let(:disabled_config) do
        test_config do |c|
          c.send(:set_validator_config, 'Tags/TypeSyntax', 'Enabled', false)
        end
      end

      it 'does not report type syntax violations' do
        result = Yard::Lint.run(path: fixture_path, config: disabled_config, progress: false)

        type_syntax_offenses = result.offenses.select { |o| o[:name] == 'InvalidTypeSyntax' }

        expect(type_syntax_offenses).to be_empty
      end
    end

    context 'when ValidatedTags is customized' do
      let(:custom_config) do
        test_config do |c|
          c.send(:set_validator_config, 'Tags/TypeSyntax', 'Enabled', true)
          c.send(:set_validator_config, 'Tags/TypeSyntax', 'ValidatedTags', ['return'])
        end
      end

      it 'only validates specified tags' do
        result = Yard::Lint.run(path: fixture_path, config: custom_config, progress: false)

        type_syntax_offenses = result.offenses.select { |o| o[:name] == 'InvalidTypeSyntax' }

        # Should find @return violations but not @param violations
        return_offenses = type_syntax_offenses.select { |o| o[:message].include?('@return') }
        param_offenses = type_syntax_offenses.select { |o| o[:message].include?('@param') }

        expect(return_offenses).not_to be_empty
        expect(param_offenses).to be_empty
      end
    end
  end

  describe 'offense details' do
    it 'includes file path in location' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find { |o| o[:name] == 'InvalidTypeSyntax' }

      expect(offense[:location]).to eq(fixture_path)
      expect(offense[:location]).not_to be_empty
    end

    it 'includes line number' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find { |o| o[:name] == 'InvalidTypeSyntax' }

      expect(offense[:location_line]).to be > 0
    end

    it 'includes descriptive message with error details' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find { |o| o[:name] == 'InvalidTypeSyntax' }

      expect(offense[:message]).to include('Invalid type syntax')
      expect(offense[:message]).to match(/@(param|return|option)/)
    end
  end
end

# frozen_string_literal: true

RSpec.describe 'ForbiddenTags Integration' do
  let(:fixture_path) { File.expand_path('../fixtures/forbidden_tags_examples.rb', __dir__) }

  describe 'detecting @return [void]' do
    let(:config) do
      test_config do |c|
        c.send(:set_validator_config, 'Tags/ForbiddenTags', 'Enabled', true)
        c.send(:set_validator_config, 'Tags/ForbiddenTags', 'ForbiddenPatterns', [
                 { 'Tag' => 'return', 'Types' => ['void'] }
               ])
      end
    end

    it 'finds @return [void] tags' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      void_offenses = result.offenses.select do |o|
        o[:name] == 'ForbiddenTags' &&
          o[:message].include?('@return') &&
          o[:message].include?('void')
      end

      expect(void_offenses).not_to be_empty
    end

    it 'does not flag @return [Boolean]' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      boolean_offenses = result.offenses.select do |o|
        o[:name] == 'ForbiddenTags' &&
          o[:message].include?('Boolean')
      end

      expect(boolean_offenses).to be_empty
    end

    it 'does not flag @return [nil]' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      nil_offenses = result.offenses.select do |o|
        o[:name] == 'ForbiddenTags' &&
          o[:message].include?('[nil]')
      end

      expect(nil_offenses).to be_empty
    end

    it 'flags @return with void among multiple types' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      # The mixed_return method has @return [String, void] which should be flagged
      # Look for offense on line 39 where mixed_return is defined
      mixed_offenses = result.offenses.select do |o|
        o[:name] == 'ForbiddenTags' &&
          o[:message].include?('String,void')
      end

      expect(mixed_offenses).not_to be_empty
    end
  end

  describe 'detecting @param [Object]' do
    let(:config) do
      test_config do |c|
        c.send(:set_validator_config, 'Tags/ForbiddenTags', 'Enabled', true)
        c.send(:set_validator_config, 'Tags/ForbiddenTags', 'ForbiddenPatterns', [
                 { 'Tag' => 'param', 'Types' => ['Object'] }
               ])
      end
    end

    it 'finds @param [Object] tags' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      object_offenses = result.offenses.select do |o|
        o[:name] == 'ForbiddenTags' &&
          o[:message].include?('@param') &&
          o[:message].include?('Object')
      end

      expect(object_offenses).not_to be_empty
    end

    it 'does not flag @param [String]' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      string_offenses = result.offenses.select do |o|
        o[:name] == 'ForbiddenTags' &&
          o[:message].include?('String')
      end

      expect(string_offenses).to be_empty
    end
  end

  describe 'detecting tag-only patterns (no types)' do
    let(:config) do
      test_config do |c|
        c.send(:set_validator_config, 'Tags/ForbiddenTags', 'Enabled', true)
        c.send(:set_validator_config, 'Tags/ForbiddenTags', 'ForbiddenPatterns', [
                 { 'Tag' => 'api' }
               ])
      end
    end

    it 'finds @api tags' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      api_offenses = result.offenses.select do |o|
        o[:name] == 'ForbiddenTags' &&
          o[:message].include?('@api')
      end

      expect(api_offenses).not_to be_empty
    end

    it 'provides helpful error message for tag-only patterns' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'ForbiddenTags' && o[:message].include?('@api')
      end

      expect(offense).not_to be_nil
      expect(offense[:message]).to include('not allowed by project configuration')
    end
  end

  describe 'multiple patterns' do
    let(:config) do
      test_config do |c|
        c.send(:set_validator_config, 'Tags/ForbiddenTags', 'Enabled', true)
        c.send(:set_validator_config, 'Tags/ForbiddenTags', 'ForbiddenPatterns', [
                 { 'Tag' => 'return', 'Types' => ['void'] },
                 { 'Tag' => 'param', 'Types' => ['Object'] },
                 { 'Tag' => 'api' }
               ])
      end
    end

    it 'detects all configured patterns' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      forbidden_offenses = result.offenses.select { |o| o[:name] == 'ForbiddenTags' }

      # Should find offenses for all three patterns
      void_found = forbidden_offenses.any? { |o| o[:message].include?('void') }
      object_found = forbidden_offenses.any? { |o| o[:message].include?('Object') }
      api_found = forbidden_offenses.any? { |o| o[:message].include?('@api') }

      expect(void_found).to be true
      expect(object_found).to be true
      expect(api_found).to be true
    end
  end

  describe 'when disabled (default)' do
    let(:config) do
      test_config do |c|
        c.send(:set_validator_config, 'Tags/ForbiddenTags', 'Enabled', false)
        c.send(:set_validator_config, 'Tags/ForbiddenTags', 'ForbiddenPatterns', [
                 { 'Tag' => 'return', 'Types' => ['void'] }
               ])
      end
    end

    it 'does not run validation' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      forbidden_offenses = result.offenses.select { |o| o[:name] == 'ForbiddenTags' }
      expect(forbidden_offenses).to be_empty
    end
  end

  describe 'with empty patterns' do
    let(:config) do
      test_config do |c|
        c.send(:set_validator_config, 'Tags/ForbiddenTags', 'Enabled', true)
        c.send(:set_validator_config, 'Tags/ForbiddenTags', 'ForbiddenPatterns', [])
      end
    end

    it 'does not report any offenses' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      forbidden_offenses = result.offenses.select { |o| o[:name] == 'ForbiddenTags' }
      expect(forbidden_offenses).to be_empty
    end
  end

  describe 'error messages' do
    let(:config) do
      test_config do |c|
        c.send(:set_validator_config, 'Tags/ForbiddenTags', 'Enabled', true)
        c.send(:set_validator_config, 'Tags/ForbiddenTags', 'ForbiddenPatterns', [
                 { 'Tag' => 'return', 'Types' => ['void'] }
               ])
      end
    end

    it 'provides descriptive messages for type patterns' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find { |o| o[:name] == 'ForbiddenTags' }
      expect(offense).not_to be_nil
      expect(offense[:message]).to include('Forbidden tag pattern detected')
      expect(offense[:message]).to include('not allowed')
    end
  end
end

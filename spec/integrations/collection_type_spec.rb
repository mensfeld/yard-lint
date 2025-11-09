# frozen_string_literal: true

RSpec.describe 'CollectionType Integration' do
  let(:fixture_path) { 'spec/fixtures/collection_type_examples.rb' }

  let(:config) do
    Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Tags/CollectionType', 'Enabled', true)
    end
  end

  describe 'detecting incorrect Hash syntax' do
    it 'finds Hash<K, V> in @param tags' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      hash_in_param = result.offenses.select do |o|
        o[:name] == 'CollectionType' &&
          o[:message].include?('Hash<Symbol, String>')
      end

      expect(hash_in_param).not_to be_empty
    end

    it 'finds nested Hash<> syntax' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      nested_hash = result.offenses.select do |o|
        o[:name] == 'CollectionType' &&
          o[:message].include?('Hash<String, Hash<Symbol')
      end

      expect(nested_hash).not_to be_empty
    end

    it 'finds Hash<> in @return tags' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      hash_in_return = result.offenses.select do |o|
        o[:name] == 'CollectionType' &&
          o[:message].include?('@return')
      end

      expect(hash_in_return).not_to be_empty
    end

    it 'does not flag Hash{} syntax' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      # All offenses should be about Hash<>, not Hash{}
      offenses = result.offenses.select { |o| o[:name] == 'CollectionType' }

      offenses.each do |offense|
        expect(offense[:message]).to include('Hash<')
        expect(offense[:message]).to include('Hash{')
      end
    end

    it 'does not flag Array<> syntax' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      # Should not have violations for Array<String>
      array_violations = result.offenses.select do |o|
        o[:name] == 'CollectionType' &&
          o[:message].include?('Array<')
      end

      expect(array_violations).to be_empty
    end

    it 'provides helpful error messages' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find { |o| o[:name] == 'CollectionType' }
      expect(offense).not_to be_nil
      expect(offense[:message]).to include('Hash{')
      expect(offense[:message]).to include('=>')
      expect(offense[:message]).to include('YARD')
    end
  end

  describe 'when disabled' do
    it 'does not run validation' do
      disabled_config = Yard::Lint::Config.new do |c|
        c.send(:set_validator_config, 'Tags/CollectionType', 'Enabled', false)
      end

      result = Yard::Lint.run(path: fixture_path, config: disabled_config, progress: false)

      collection_type_offenses = result.offenses.select { |o| o[:name] == 'CollectionType' }
      expect(collection_type_offenses).to be_empty
    end
  end
end

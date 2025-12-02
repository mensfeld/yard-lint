# frozen_string_literal: true

RSpec.describe 'MeaninglessTag Integration' do
  let(:fixture_path) { File.expand_path('../fixtures/meaningless_tag_examples.rb', __dir__) }

  let(:config) do
    test_config do |c|
      c.send(:set_validator_config, 'Tags/MeaninglessTag', 'Enabled', true)
    end
  end

  describe 'detecting meaningless tags' do
    it 'finds @param tags on classes' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      param_on_class = result.offenses.select do |o|
        o[:name] == 'MeaninglessTag' &&
          o[:message].include?('@param') &&
          o[:message].include?('class')
      end

      expect(param_on_class).not_to be_empty
    end

    it 'finds @option tags on modules' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      option_on_module = result.offenses.select do |o|
        o[:name] == 'MeaninglessTag' &&
          o[:message].include?('@option') &&
          o[:message].include?('module')
      end

      expect(option_on_module).not_to be_empty
    end

    it 'finds @param tags on constants' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      param_on_constant = result.offenses.select do |o|
        o[:name] == 'MeaninglessTag' &&
          o[:message].include?('@param') &&
          o[:message].include?('constant')
      end

      expect(param_on_constant).not_to be_empty
    end

    it 'does not flag valid @param tags on methods' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      # All offenses should be on classes/modules/constants, not methods
      offenses = result.offenses.select { |o| o[:name] == 'MeaninglessTag' }

      offenses.each do |offense|
        # Check that the offense is about a class, module, or constant (not a method)
        expect(offense[:message]).to match(/on a (class|module|constant)/)
      end
    end

    it 'provides helpful error messages' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find { |o| o[:name] == 'MeaninglessTag' }
      expect(offense).not_to be_nil
      expect(offense[:message]).to include('meaningless')
      expect(offense[:message]).to include('only makes sense on methods')
    end
  end

  describe 'when disabled' do
    let(:config) do
      test_config do |c|
        c.send(:set_validator_config, 'Tags/MeaninglessTag', 'Enabled', false)
      end
    end

    it 'does not run validation' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      meaningless_tag_offenses = result.offenses.select { |o| o[:name] == 'MeaninglessTag' }
      expect(meaningless_tag_offenses).to be_empty
    end
  end
end

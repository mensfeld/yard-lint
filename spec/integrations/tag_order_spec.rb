# frozen_string_literal: true

RSpec.describe 'Tags/Order Integration' do
  let(:fixture_path) { File.expand_path('../fixtures/tag_order_examples.rb', __dir__) }

  let(:config) do
    test_config do |c|
      c.send(:set_validator_config, 'Tags/Order', 'Enabled', true)
    end
  end

  describe 'detecting invalid tag order' do
    it 'detects @return before @param' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offenses = result.offenses.select do |o|
        o[:name] == 'InvalidTagOrder' &&
          o[:message].include?('return_before_param')
      end

      expect(offenses).not_to be_empty
      expect(offenses.first[:message]).to include('param')
      expect(offenses.first[:message]).to include('return')
    end

    it 'detects @note before @return' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offenses = result.offenses.select do |o|
        o[:name] == 'InvalidTagOrder' &&
          o[:message].include?('note_before_return')
      end

      expect(offenses).not_to be_empty
    end

    it 'detects @note before @example' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offenses = result.offenses.select do |o|
        o[:name] == 'InvalidTagOrder' &&
          o[:message].include?('note_before_example')
      end

      expect(offenses).not_to be_empty
    end

    it 'detects @see before @return' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offenses = result.offenses.select do |o|
        o[:name] == 'InvalidTagOrder' &&
          o[:message].include?('see_before_return')
      end

      expect(offenses).not_to be_empty
    end

    it 'detects @todo before @note' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offenses = result.offenses.select do |o|
        o[:name] == 'InvalidTagOrder' &&
          o[:message].include?('todo_before_note')
      end

      expect(offenses).not_to be_empty
    end

    it 'detects @yield tags in wrong order' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offenses = result.offenses.select do |o|
        o[:name] == 'InvalidTagOrder' &&
          o[:message].include?('yield_tags_wrong_order')
      end

      expect(offenses).not_to be_empty
    end

    it 'detects @raise before @return' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offenses = result.offenses.select do |o|
        o[:name] == 'InvalidTagOrder' &&
          o[:message].include?('raise_before_return')
      end

      expect(offenses).not_to be_empty
    end
  end

  describe 'correct tag order' do
    it 'does not flag methods with correct full tag order' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offenses = result.offenses.select do |o|
        o[:name] == 'InvalidTagOrder' &&
          o[:message].include?('correct_full_order')
      end

      expect(offenses).to be_empty
    end

    it 'does not flag methods with correct partial tag order' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offenses = result.offenses.select do |o|
        o[:name] == 'InvalidTagOrder' &&
          o[:message].include?('correct_partial_order')
      end

      expect(offenses).to be_empty
    end

    it 'does not flag simple param-return order' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offenses = result.offenses.select do |o|
        o[:name] == 'InvalidTagOrder' &&
          o[:message].include?('simple_correct_order')
      end

      expect(offenses).to be_empty
    end
  end

  describe 'consecutive same tags' do
    it 'does not flag multiple consecutive @param tags' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offenses = result.offenses.select do |o|
        o[:name] == 'InvalidTagOrder' &&
          o[:message].include?('multiple_params')
      end

      expect(offenses).to be_empty
    end

    it 'does not flag multiple consecutive @note tags' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offenses = result.offenses.select do |o|
        o[:name] == 'InvalidTagOrder' &&
          o[:message].include?('multiple_notes')
      end

      expect(offenses).to be_empty
    end

    it 'does not flag multiple consecutive @example tags' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offenses = result.offenses.select do |o|
        o[:name] == 'InvalidTagOrder' &&
          o[:message].include?('multiple_examples')
      end

      expect(offenses).to be_empty
    end
  end

  describe 'enforced order configuration' do
    it 'uses the full default order from config' do
      defaults = Yard::Lint::Validators::Tags::Order::Config.defaults
      expected_order = %w[param option yield yieldparam yieldreturn return raise see example note todo]

      expect(defaults['EnforcedOrder']).to eq(expected_order)
    end
  end

  describe 'when disabled' do
    let(:config) do
      test_config do |c|
        c.send(:set_validator_config, 'Tags/Order', 'Enabled', false)
      end
    end

    it 'does not run validation' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
      expect(order_offenses).to be_empty
    end
  end
end

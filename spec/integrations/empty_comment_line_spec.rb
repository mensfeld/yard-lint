# frozen_string_literal: true

RSpec.describe 'EmptyCommentLine Integration' do
  let(:fixture_path) { File.expand_path('../fixtures/empty_comment_lines.rb', __dir__) }

  let(:config) do
    test_config do |c|
      c.send(:set_validator_config, 'Documentation/EmptyCommentLine', 'Enabled', true)
    end
  end

  describe 'detecting empty comment lines' do
    it 'finds leading empty comment lines' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      leading_offenses = result.offenses.select do |o|
        o[:name] == 'EmptyCommentLine' &&
          o[:message].include?('leading')
      end

      # Should find in: LeadingEmptyClass, BothEmptyClass, leading_method
      expect(leading_offenses.size).to eq(3)
    end

    it 'finds trailing empty comment lines' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      trailing_offenses = result.offenses.select do |o|
        o[:name] == 'EmptyCommentLine' &&
          o[:message].include?('trailing')
      end

      # Should find in: TrailingEmptyClass, BothEmptyClass, trailing_method,
      # multiple_trailing (2 lines)
      expect(trailing_offenses.size).to eq(5)
    end

    it 'does not flag empty lines between sections' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      # valid_with_spacing has empty lines between description and @param
      # and between @param and @return - these should NOT be flagged
      valid_spacing_offenses = result.offenses.select do |o|
        o[:name] == 'EmptyCommentLine' &&
          o[:location]&.include?('valid_with_spacing')
      end

      expect(valid_spacing_offenses).to be_empty
    end

    it 'provides helpful error messages' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find { |o| o[:name] == 'EmptyCommentLine' }

      expect(offense).not_to be_nil
      expect(offense[:message]).to match(/Empty (leading|trailing) comment line/)
      expect(offense[:message]).to include('line')
    end
  end

  describe 'configuration options' do
    context 'when only checking leading' do
      let(:leading_only_config) do
        test_config do |c|
          c.send(:set_validator_config, 'Documentation/EmptyCommentLine', 'Enabled', true)
          c.send(:set_validator_config, 'Documentation/EmptyCommentLine', 'EnabledPatterns', {
                   'Leading' => true,
                   'Trailing' => false
                 })
        end
      end

      it 'only finds leading empty lines' do
        result = Yard::Lint.run(path: fixture_path, config: leading_only_config, progress: false)

        offenses = result.offenses.select { |o| o[:name] == 'EmptyCommentLine' }

        offenses.each do |offense|
          expect(offense[:message]).to include('leading')
          expect(offense[:message]).not_to include('trailing')
        end
      end
    end

    context 'when only checking trailing' do
      let(:trailing_only_config) do
        test_config do |c|
          c.send(:set_validator_config, 'Documentation/EmptyCommentLine', 'Enabled', true)
          c.send(:set_validator_config, 'Documentation/EmptyCommentLine', 'EnabledPatterns', {
                   'Leading' => false,
                   'Trailing' => true
                 })
        end
      end

      it 'only finds trailing empty lines' do
        result = Yard::Lint.run(path: fixture_path, config: trailing_only_config, progress: false)

        offenses = result.offenses.select { |o| o[:name] == 'EmptyCommentLine' }

        offenses.each do |offense|
          expect(offense[:message]).to include('trailing')
          expect(offense[:message]).not_to include('leading')
        end
      end
    end
  end

  describe 'when disabled' do
    it 'does not run validation' do
      disabled_config = test_config do |c|
        c.send(:set_validator_config, 'Documentation/EmptyCommentLine', 'Enabled', false)
      end

      result = Yard::Lint.run(path: fixture_path, config: disabled_config, progress: false)

      empty_comment_offenses = result.offenses.select { |o| o[:name] == 'EmptyCommentLine' }
      expect(empty_comment_offenses).to be_empty
    end
  end

  describe 'valid documentation is not flagged' do
    it 'does not flag properly formatted docs' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      # ValidClass and valid_method have proper formatting
      # They should not appear in offenses
      valid_class_offenses = result.offenses.select do |o|
        o[:name] == 'EmptyCommentLine' &&
          o[:message].include?('ValidClass')
      end

      valid_method_offenses = result.offenses.select do |o|
        o[:name] == 'EmptyCommentLine' &&
          o[:message].include?('valid_method')
      end

      expect(valid_class_offenses).to be_empty
      expect(valid_method_offenses).to be_empty
    end
  end
end

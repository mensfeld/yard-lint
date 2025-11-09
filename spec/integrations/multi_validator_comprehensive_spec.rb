# frozen_string_literal: true

RSpec.describe 'Multi-Validator Comprehensive Integration' do
  let(:fixture_path) do
    File.expand_path('spec/integrations/fixtures/multi_validator_comprehensive.rb')
  end

  describe 'With default configuration' do
    it 'detects multiple types of offenses simultaneously' do
      result = Yard::Lint.run(path: fixture_path, progress: false)

      offense_names = result.offenses.map { |o| o[:name] }.uniq

      # Should find several different types of offenses
      expect(offense_names).to include('InvalidTagOrder')
      expect(offense_names).to include('UnknownParameterName')
      expect(offense_names).to include('InvalidTypeSyntax')
      expect(result.count).to be > 5
    end

    it 'finds offenses across multiple scenarios in the fixture' do
      result = Yard::Lint.run(path: fixture_path, progress: false)

      # Group by line to see distribution
      lines_with_issues = result.offenses.map { |o| o[:location_line] }.uniq

      # Should have issues in multiple different methods/classes
      expect(lines_with_issues.size).to be >= 5
    end

    it 'handles kitchen sink method with many issues' do
      result = Yard::Lint.run(path: fixture_path, progress: false)

      # Kitchen sink method is at line 89
      kitchen_sink_offenses = result.offenses.select do |o|
        o[:location_line] == 89
      end

      # Should find multiple issues in this complex method
      expect(kitchen_sink_offenses.size).to be >= 3
      expect(kitchen_sink_offenses.map { |o| o[:name] }.uniq.size).to be >= 2
    end
  end

  describe 'Multiple validators enabled together' do
    let(:config) do
      Yard::Lint::Config.new do |c|
        c.send(:set_validator_config, 'Tags/Order', 'Enabled', true)
        c.send(:set_validator_config, 'Tags/TypeSyntax', 'Enabled', true)
        c.send(:set_validator_config, 'Warnings/UnknownParameterName', 'Enabled', true)
        c.send(:set_validator_config, 'Warnings/DuplicatedParameterName', 'Enabled', true)
        c.send(:set_validator_config, 'Warnings/UnknownTag', 'Enabled', true)
      end
    end

    it 'runs all enabled validators and finds multiple issue types' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense_names = result.offenses.map { |o| o[:name] }.uniq

      # Should have offenses from multiple validators
      expect(offense_names).to include('InvalidTagOrder')
      expect(offense_names).to include('InvalidTypeSyntax')
      expect(offense_names).to include('UnknownParameterName')
    end

    it 'detects duplicate parameter names' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      duplicated = result.offenses.select { |o| o[:name] == 'DuplicatedParameterName' }
      expect(duplicated).not_to be_empty
    end

    it 'detects unknown tags' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      unknown_tags = result.offenses.select { |o| o[:name] == 'UnknownTag' }
      expect(unknown_tags).not_to be_empty
    end
  end

  describe 'Type validation validators together' do
    let(:config) do
      Yard::Lint::Config.new do |c|
        c.send(:set_validator_config, 'Tags/TypeSyntax', 'Enabled', true)
        c.send(:set_validator_config, 'Tags/InvalidTypes', 'Enabled', true)
      end
    end

    it 'runs both type validators without conflicts' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      type_syntax = result.offenses.select { |o| o[:name] == 'InvalidTypeSyntax' }
      invalid_types = result.offenses.select { |o| o[:name] == 'InvalidTypes' }

      # TypeSyntax should find issues
      expect(type_syntax).not_to be_empty

      # Both can coexist
      expect(type_syntax).to be_an(Array)
      expect(invalid_types).to be_an(Array)
    end

    it 'finds multiple type syntax errors' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      type_syntax = result.offenses.select { |o| o[:name] == 'InvalidTypeSyntax' }

      # Should find unclosed brackets, empty generics, malformed hash types
      expect(type_syntax.size).to be >= 3
    end
  end

  describe 'Documentation validators together' do
    let(:config) do
      Yard::Lint::Config.new do |c|
        c.send(:set_validator_config, 'Documentation/UndocumentedMethodArguments', 'Enabled', true)
      end
    end

    it 'detects missing method argument documentation' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      undocumented_args = result.offenses.select { |o| o[:name] == 'UndocumentedMethodArgument' }

      # Multiple methods have missing @param tags
      expect(undocumented_args).not_to be_empty
    end
  end

  describe 'Performance with many validators' do
    let(:config) do
      Yard::Lint::Config.new do |c|
        # Enable many validators
        c.send(:set_validator_config, 'Tags/Order', 'Enabled', true)
        c.send(:set_validator_config, 'Tags/TypeSyntax', 'Enabled', true)
        c.send(:set_validator_config, 'Tags/InvalidTypes', 'Enabled', true)
        c.send(:set_validator_config, 'Warnings/UnknownParameterName', 'Enabled', true)
        c.send(:set_validator_config, 'Warnings/DuplicatedParameterName', 'Enabled', true)
        c.send(:set_validator_config, 'Warnings/UnknownTag', 'Enabled', true)
        c.send(:set_validator_config, 'Documentation/UndocumentedObjects', 'Enabled', true)
        c.send(:set_validator_config, 'Documentation/UndocumentedMethodArguments', 'Enabled', true)
      end
    end

    it 'completes analysis in reasonable time' do
      start_time = Time.now
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
      elapsed = Time.now - start_time

      expect(elapsed).to be < 15 # Should complete within 15 seconds
      expect(result.count).to be > 5
    end

    it 'finds offenses from multiple validator categories' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense_names = result.offenses.map { |o| o[:name] }.uniq

      # Should have offenses from different categories
      has_tags = offense_names.any? { |n| %w[InvalidTagOrder InvalidTypeSyntax].include?(n) }
      has_warnings = offense_names.any? do |n|
        %w[UnknownParameterName DuplicatedParameterName].include?(n)
      end
      has_documentation = offense_names.any? { |n| n.start_with?('Undocumented') }

      expect(has_tags).to be true
      expect(has_warnings).to be true
      expect(has_documentation).to be true
    end

    it 'produces consistent results across runs' do
      result1 = Yard::Lint.run(path: fixture_path, config: config, progress: false)
      result2 = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      expect(result1.count).to eq(result2.count)
    end
  end
end

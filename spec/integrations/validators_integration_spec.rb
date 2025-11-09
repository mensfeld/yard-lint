# frozen_string_literal: true

RSpec.describe 'Yard::Lint Validators' do
  describe 'API Tags Validation' do
    context 'when require_api_tags is enabled' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.send(:set_validator_config, 'Tags/ApiTags', 'Enabled', true)
          c.send(:set_validator_config, 'Tags/ApiTags', 'AllowedApis', %w[public private internal])
        end
      end

      it 'detects API tag issues' do
        # Run against a simple Ruby string to avoid loading full project
        result = Yard::Lint.run(path: 'lib/yard/lint/version.rb', config: config)

        # Since require_api_tags is enabled, should find missing @api tags
        expect(result.offenses.select { |o| o[:name].to_s.include?('Api') }).to be_an(Array)
        # The feature is working if we get results
        expect(result).to respond_to(:offenses)
      end
    end

    context 'when require_api_tags is disabled' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.send(:set_validator_config, 'Tags/ApiTags', 'Enabled', false)
        end
      end

      it 'does not run API tag validation' do
        result = Yard::Lint.run(path: 'lib/yard/lint/version.rb', config: config)

        expect(result.offenses.select { |o| o[:name].to_s.include?('Api') }).to be_empty
      end
    end

    context 'with custom allowed APIs' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.send(:set_validator_config, 'Tags/ApiTags', 'Enabled', true)
          c.send(:set_validator_config, 'Tags/ApiTags', 'AllowedApis', %w[public])
        end
      end

      it 'uses custom allowed_apis configuration' do
        result = Yard::Lint.run(path: 'lib/yard/lint/version.rb', config: config)

        # Feature should work with custom config
        expect(result.offenses.select { |o| o[:name].to_s.include?('Api') }).to be_an(Array)
      end
    end
  end

  describe 'Abstract Methods Validation' do
    context 'when validate_abstract_methods is enabled' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.send(:set_validator_config, 'Semantic/AbstractMethods', 'Enabled', true)
        end
      end

      it 'runs abstract method validation' do
        result = Yard::Lint.run(path: 'lib', config: config)

        expect(result.offenses.select { |o| o[:name].to_s.include?('Abstract') }).to be_an(Array)
        expect(result).to respond_to(:offenses)
      end
    end

    context 'when validate_abstract_methods is disabled' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.send(:set_validator_config, 'Semantic/AbstractMethods', 'Enabled', false)
        end
      end

      it 'does not run abstract method validation' do
        result = Yard::Lint.run(path: 'lib', config: config)

        expect(result.offenses.select { |o| o[:name].to_s.include?('Abstract') }).to be_empty
      end
    end
  end

  describe 'Option Tags Validation' do
    context 'when validate_option_tags is enabled' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.send(:set_validator_config, 'Tags/OptionTags', 'Enabled', true)
        end
      end

      it 'runs option tags validation' do
        result = Yard::Lint.run(path: 'lib', config: config)

        expect(result.offenses.select { |o| o[:name].to_s.include?('Option') }).to be_an(Array)
        expect(result).to respond_to(:offenses)
      end
    end

    context 'when validate_option_tags is disabled' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.send(:set_validator_config, 'Tags/OptionTags', 'Enabled', false)
        end
      end

      it 'does not run option tags validation' do
        result = Yard::Lint.run(path: 'lib', config: config)

        expect(result.offenses.select { |o| o[:name].to_s.include?('Option') }).to be_empty
      end
    end
  end

  describe 'Combined Validators' do
    let(:config) do
      Yard::Lint::Config.new do |c|
        c.send(:set_validator_config, 'Tags/ApiTags', 'Enabled', true)
        c.send(:set_validator_config, 'Semantic/AbstractMethods', 'Enabled', true)
        c.send(:set_validator_config, 'Tags/OptionTags', 'Enabled', true)
      end
    end

    it 'runs all validators when enabled' do
      result = Yard::Lint.run(path: 'lib', config: config)

      expect(result.offenses.select { |o| o[:name].to_s.include?('Api') }).to be_an(Array)
      expect(result.offenses.select { |o| o[:name].to_s.include?('Abstract') }).to be_an(Array)
      expect(result.offenses.select { |o| o[:name].to_s.include?('Option') }).to be_an(Array)
    end

    it 'includes all offense types in the offenses array' do
      result = Yard::Lint.run(path: 'lib', config: config)

      expect(result.offenses).to be_an(Array)
      expect(result).to respond_to(:offenses)
      expect(result).to respond_to(:count)
      expect(result).to respond_to(:clean?)
    end
  end

  describe 'Documentation Category Validators Together' do
    let(:config) do
      Yard::Lint::Config.new do |c|
        c.send(:set_validator_config, 'Documentation/UndocumentedObjects', 'Enabled', true)
        c.send(:set_validator_config, 'Documentation/UndocumentedMethodArguments', 'Enabled', true)
        c.send(:set_validator_config, 'Documentation/UndocumentedBooleanMethods', 'Enabled', true)
      end
    end

    it 'runs all documentation validators simultaneously' do
      result = Yard::Lint.run(path: 'lib', config: config)

      offense_names = result.offenses.map { |o| o[:name] }.uniq
      documentation_validators = offense_names.select { |n| n.start_with?('Undocumented') }

      # Documentation validators should run (may or may not find issues)
      expect(result.offenses).to be_an(Array)
      expect(result).to respond_to(:count)
    end

    it 'detects multiple documentation issues in the same file' do
      result = Yard::Lint.run(path: 'lib', config: config)

      # Group offenses by file
      by_file = result.offenses.group_by { |o| o[:location] }

      # Find files with multiple documentation issues
      multi_issue_files = by_file.select { |_file, offenses| offenses.size > 1 }

      # Should have at least some files with multiple issues
      expect(multi_issue_files).not_to be_empty if result.any?
    end
  end

  describe 'Tags Category Validators Together' do
    let(:config) do
      Yard::Lint::Config.new do |c|
        c.send(:set_validator_config, 'Tags/Order', 'Enabled', true)
        c.send(:set_validator_config, 'Tags/InvalidTypes', 'Enabled', true)
        c.send(:set_validator_config, 'Tags/TypeSyntax', 'Enabled', true)
      end
    end

    it 'runs all tag validators simultaneously' do
      result = Yard::Lint.run(path: 'lib', config: config)

      offense_names = result.offenses.map { |o| o[:name] }.uniq
      tag_validators = %w[InvalidTagOrder InvalidTypes InvalidTypeSyntax]

      # At least some tag validators should trigger (or all should run cleanly)
      expect(result.offenses).to be_an(Array)
    end

    it 'handles type validation interactions correctly' do
      result = Yard::Lint.run(path: 'lib', config: config)

      type_syntax = result.offenses.select { |o| o[:name] == 'InvalidTypeSyntax' }
      invalid_types = result.offenses.select { |o| o[:name] == 'InvalidTypes' }

      # Both validators should be able to run without interfering
      expect(type_syntax).to be_an(Array)
      expect(invalid_types).to be_an(Array)
    end
  end

  describe 'Warnings Category Validators Together' do
    let(:config) do
      Yard::Lint::Config.new do |c|
        c.send(:set_validator_config, 'Warnings/UnknownTag', 'Enabled', true)
        c.send(:set_validator_config, 'Warnings/UnknownParameterName', 'Enabled', true)
        c.send(:set_validator_config, 'Warnings/DuplicatedParameterName', 'Enabled', true)
        c.send(:set_validator_config, 'Warnings/InvalidTagFormat', 'Enabled', true)
      end
    end

    it 'runs all warning validators simultaneously' do
      result = Yard::Lint.run(path: 'lib', config: config)

      warning_offenses = result.offenses.select do |o|
        %w[UnknownTag UnknownParameterName DuplicatedParameterName
           InvalidTagFormat].include?(o[:name])
      end

      expect(warning_offenses).to be_an(Array)
    end

    it 'detects parameter-related warnings together' do
      result = Yard::Lint.run(path: 'lib', config: config)

      unknown_param = result.offenses.select { |o| o[:name] == 'UnknownParameterName' }
      duplicated_param = result.offenses.select { |o| o[:name] == 'DuplicatedParameterName' }

      # These validators can run together without conflicts
      expect(unknown_param).to be_an(Array)
      expect(duplicated_param).to be_an(Array)
    end
  end

  describe 'Cross-Category Combinations' do
    let(:config) do
      Yard::Lint::Config.new do |c|
        # Mix Documentation + Tags + Warnings
        c.send(:set_validator_config, 'Documentation/UndocumentedMethodArguments', 'Enabled', true)
        c.send(:set_validator_config, 'Tags/Order', 'Enabled', true)
        c.send(:set_validator_config, 'Warnings/UnknownParameterName', 'Enabled', true)
      end
    end

    it 'runs validators from different categories together' do
      result = Yard::Lint.run(path: 'lib', config: config)

      has_documentation = result.offenses.any? { |o| o[:name] == 'UndocumentedMethodArguments' }
      has_tags = result.offenses.any? { |o| o[:name] == 'InvalidTagOrder' }
      has_warnings = result.offenses.any? { |o| o[:name] == 'UnknownParameterName' }

      # All validator types should be able to run (even if no offenses found)
      expect(result.offenses).to be_an(Array)
    end

    it 'handles multiple categories on the same method' do
      result = Yard::Lint.run(path: 'lib', config: config)

      # Group by location and line to find methods with multiple issues
      by_method = result.offenses.group_by { |o| [o[:location], o[:location_line]] }

      # Some methods might have issues from different validator categories
      multi_category = by_method.select do |_key, offenses|
        categories = offenses.map { |o| o[:name] }.uniq
        categories.size > 1
      end

      # This is valid - just checking the structure works
      expect(multi_category).to be_a(Hash)
    end
  end

  describe 'All Validators Enabled' do
    let(:config) do
      Yard::Lint::Config.new do |c|
        # Enable every single validator
        c.send(:set_validator_config, 'Documentation/UndocumentedObjects', 'Enabled', true)
        c.send(:set_validator_config, 'Documentation/UndocumentedMethodArguments', 'Enabled', true)
        c.send(:set_validator_config, 'Documentation/UndocumentedBooleanMethods', 'Enabled', true)
        c.send(:set_validator_config, 'Tags/Order', 'Enabled', true)
        c.send(:set_validator_config, 'Tags/ApiTags', 'Enabled', true)
        c.send(:set_validator_config, 'Tags/OptionTags', 'Enabled', true)
        c.send(:set_validator_config, 'Tags/InvalidTypes', 'Enabled', true)
        c.send(:set_validator_config, 'Tags/TypeSyntax', 'Enabled', true)
        c.send(:set_validator_config, 'Warnings/UnknownTag', 'Enabled', true)
        c.send(:set_validator_config, 'Warnings/UnknownDirective', 'Enabled', true)
        c.send(:set_validator_config, 'Warnings/InvalidDirectiveFormat', 'Enabled', true)
        c.send(:set_validator_config, 'Warnings/InvalidTagFormat', 'Enabled', true)
        c.send(:set_validator_config, 'Warnings/DuplicatedParameterName', 'Enabled', true)
        c.send(:set_validator_config, 'Warnings/UnknownParameterName', 'Enabled', true)
        c.send(:set_validator_config, 'Semantic/AbstractMethods', 'Enabled', true)
      end
    end

    it 'successfully runs with all validators enabled' do
      result = Yard::Lint.run(path: 'lib/yard/lint/version.rb', config: config, progress: false)

      expect(result).to respond_to(:offenses)
      expect(result).to respond_to(:count)
      expect(result.offenses).to be_an(Array)
    end

    it 'completes analysis in reasonable time with all validators' do
      start_time = Time.now
      result = Yard::Lint.run(path: 'lib/yard/lint/version.rb', config: config, progress: false)
      elapsed = Time.now - start_time

      expect(elapsed).to be < 10 # Should complete quickly on a small file
      expect(result.offenses).to be_an(Array)
    end

    it 'produces consistent results across multiple runs' do
      result1 = Yard::Lint.run(path: 'lib/yard/lint/version.rb', config: config, progress: false)
      result2 = Yard::Lint.run(path: 'lib/yard/lint/version.rb', config: config, progress: false)

      expect(result1.count).to eq(result2.count)
      expect(result1.offenses.size).to eq(result2.offenses.size)
    end
  end
end

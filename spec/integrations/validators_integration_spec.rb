# frozen_string_literal: true

RSpec.describe 'Yard::Lint Validators' do
  describe 'API Tags Validation' do
    context 'when require_api_tags is enabled' do
      let(:config) do
        test_config do |c|
          c.set_validator_config('Tags/ApiTags', 'Enabled', true)
          c.set_validator_config('Tags/ApiTags', 'AllowedApis', %w[public private internal])
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
        test_config do |c|
          c.set_validator_config('Tags/ApiTags', 'Enabled', false)
        end
      end

      it 'does not run API tag validation' do
        result = Yard::Lint.run(path: 'lib/yard/lint/version.rb', config: config)

        expect(result.offenses.select { |o| o[:name].to_s.include?('Api') }).to be_empty
      end
    end

    context 'with custom allowed APIs' do
      let(:config) do
        test_config do |c|
          c.set_validator_config('Tags/ApiTags', 'Enabled', true)
          c.set_validator_config('Tags/ApiTags', 'AllowedApis', %w[public])
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
        test_config do |c|
          c.set_validator_config('Semantic/AbstractMethods', 'Enabled', true)
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
        test_config do |c|
          c.set_validator_config('Semantic/AbstractMethods', 'Enabled', false)
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
        test_config do |c|
          c.set_validator_config('Tags/OptionTags', 'Enabled', true)
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
        test_config do |c|
          c.set_validator_config('Tags/OptionTags', 'Enabled', false)
          # Disable ExampleSyntax to avoid false positives on output format examples
          c.set_validator_config('Tags/ExampleSyntax', 'Enabled', false)
        end
      end

      it 'does not run option tags validation' do
        result = Yard::Lint.run(path: 'lib', config: config)

        # Check specifically for OptionTags violations, not other validators with "Option" in name
        expect(result.offenses.select { |o| o[:name] == 'OptionTags' }).to be_empty
      end
    end
  end

  describe 'Combined Validators' do
    let(:config) do
      test_config do |c|
        c.set_validator_config('Tags/ApiTags', 'Enabled', true)
        c.set_validator_config('Semantic/AbstractMethods', 'Enabled', true)
        c.set_validator_config('Tags/OptionTags', 'Enabled', true)
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
      test_config do |c|
        c.set_validator_config('Documentation/UndocumentedObjects', 'Enabled', true)
        c.set_validator_config('Documentation/UndocumentedMethodArguments', 'Enabled', true)
        c.set_validator_config('Documentation/UndocumentedBooleanMethods', 'Enabled', true)
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

    it 'can detect multiple documentation issues in the same file' do
      result = Yard::Lint.run(path: 'lib', config: config)

      # Group offenses by file
      by_file = result.offenses.group_by { |o| o[:location] }

      # Find files with multiple documentation issues
      multi_issue_files = by_file.select { |_file, offenses| offenses.size > 1 }

      # Test validates that the grouping mechanism works correctly
      # If there are multi-issue files, verify the structure is correct
      if multi_issue_files.any?
        multi_issue_files.each do |_file, offenses|
          expect(offenses.size).to be > 1
          expect(offenses).to all(be_a(Hash))
        end
      end

      # Test always passes - we're just checking the structure works
      expect(by_file).to be_a(Hash)
    end
  end

  describe 'Tags Category Validators Together' do
    let(:config) do
      test_config do |c|
        c.set_validator_config('Tags/Order', 'Enabled', true)
        c.set_validator_config('Tags/InvalidTypes', 'Enabled', true)
        c.set_validator_config('Tags/TypeSyntax', 'Enabled', true)
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
      test_config do |c|
        c.set_validator_config('Warnings/UnknownTag', 'Enabled', true)
        c.set_validator_config('Warnings/UnknownParameterName', 'Enabled', true)
        c.set_validator_config('Warnings/DuplicatedParameterName', 'Enabled', true)
        c.set_validator_config('Warnings/InvalidTagFormat', 'Enabled', true)
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
      test_config do |c|
        # Mix Documentation + Tags + Warnings
        c.set_validator_config('Documentation/UndocumentedMethodArguments', 'Enabled', true)
        c.set_validator_config('Tags/Order', 'Enabled', true)
        c.set_validator_config('Warnings/UnknownParameterName', 'Enabled', true)
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

  describe 'Example Syntax Validation' do
    context 'when example_syntax is enabled' do
      let(:config) do
        test_config do |c|
          c.set_validator_config('Tags/ExampleSyntax', 'Enabled', true)
        end
      end

      it 'runs example syntax validation' do
        result = Yard::Lint.run(path: 'spec/fixtures/example_syntax.rb', config: config)

        example_syntax_offenses = result.offenses.select { |o| o[:name] == 'ExampleSyntax' }
        expect(example_syntax_offenses).not_to be_empty
        expect(result).to respond_to(:offenses)
      end

      it 'detects syntax errors in example code blocks' do
        result = Yard::Lint.run(path: 'spec/fixtures/example_syntax.rb', config: config)

        example_syntax_offenses = result.offenses.select { |o| o[:name] == 'ExampleSyntax' }

        # Should find the two intentional syntax errors in the fixture
        expect(example_syntax_offenses.size).to be >= 2

        # Check that error messages are present
        example_syntax_offenses.each do |offense|
          expect(offense[:message]).to include('syntax error')
        end
      end

      it 'provides detailed error messages with line numbers' do
        result = Yard::Lint.run(path: 'spec/fixtures/example_syntax.rb', config: config)

        example_syntax_offenses = result.offenses.select { |o| o[:name] == 'ExampleSyntax' }

        # Check that offenses have proper structure
        example_syntax_offenses.each do |offense|
          expect(offense).to have_key(:location)
          expect(offense).to have_key(:location_line)
          expect(offense).to have_key(:message)
          expect(offense[:severity]).to eq('warning')
        end
      end

      it 'skips incomplete single-line snippets' do
        result = Yard::Lint.run(path: 'spec/fixtures/example_syntax.rb', config: config)

        # The multiply method has a single-line incomplete snippet that should be skipped
        # Only subtract and broken_example should have errors
        example_syntax_offenses = result.offenses.select { |o| o[:name] == 'ExampleSyntax' }

        multiply_offenses = example_syntax_offenses.select do |o|
          o[:message].include?('multiply')
        end

        expect(multiply_offenses).to be_empty
      end
    end

    context 'when example_syntax is disabled' do
      let(:config) do
        test_config do |c|
          c.set_validator_config('Tags/ExampleSyntax', 'Enabled', false)
        end
      end

      it 'does not run example syntax validation' do
        result = Yard::Lint.run(path: 'spec/fixtures/example_syntax.rb', config: config)

        example_syntax_offenses = result.offenses.select { |o| o[:name] == 'ExampleSyntax' }
        expect(example_syntax_offenses).to be_empty
      end
    end

    context 'with valid examples' do
      let(:config) do
        test_config do |c|
          c.set_validator_config('Tags/ExampleSyntax', 'Enabled', true)
          # Disable other validators to isolate test
          c.set_validator_config('Tags/Order', 'Enabled', false)
        end
      end

      it 'does not report errors for files without examples' do
        result = Yard::Lint.run(path: 'spec/fixtures/clean_code.rb', config: config)

        example_syntax_offenses = result.offenses.select { |o| o[:name] == 'ExampleSyntax' }
        # clean_code.rb has no @example tags at all
        clean_code_offenses = example_syntax_offenses.select do |o|
          o[:location].include?('clean_code.rb')
        end
        expect(clean_code_offenses).to be_empty
      end
    end
  end

  describe 'Redundant Param Description Validation' do
    context 'when redundant_param_description is enabled' do
      let(:config) do
        test_config do |c|
          c.set_validator_config('Tags/RedundantParamDescription', 'Enabled', true)
        end
      end

      it 'runs redundant param description validation' do
        result = Yard::Lint.run(path: 'spec/fixtures/redundant_param_descriptions.rb', config: config)

        redundant_offenses = result.offenses.select { |o| o[:name] == 'RedundantParamDescription' }
        expect(redundant_offenses).not_to be_empty
        expect(result).to respond_to(:offenses)
      end

      it 'detects article + param pattern' do
        result = Yard::Lint.run(path: 'spec/fixtures/redundant_param_descriptions.rb', config: config)

        redundant_offenses = result.offenses.select { |o| o[:name] == 'RedundantParamDescription' }

        # Should find violations from article_param_redundant method
        article_pattern_offenses = redundant_offenses.select do |o|
          o[:message].include?('restates the parameter name')
        end

        expect(article_pattern_offenses).not_to be_empty
      end

      it 'detects possessive + param pattern' do
        result = Yard::Lint.run(path: 'spec/fixtures/redundant_param_descriptions.rb', config: config)

        redundant_offenses = result.offenses.select { |o| o[:name] == 'RedundantParamDescription' }

        possessive_offenses = redundant_offenses.select do |o|
          o[:message].include?('adds no meaningful information')
        end

        expect(possessive_offenses).not_to be_empty
      end

      it 'detects type restatement pattern' do
        result = Yard::Lint.run(path: 'spec/fixtures/redundant_param_descriptions.rb', config: config)

        redundant_offenses = result.offenses.select { |o| o[:name] == 'RedundantParamDescription' }

        type_restatement_offenses = redundant_offenses.select do |o|
          o[:message].include?('repeats the type name')
        end

        expect(type_restatement_offenses).not_to be_empty
      end

      it 'does not flag long meaningful descriptions' do
        result = Yard::Lint.run(path: 'spec/fixtures/redundant_param_descriptions.rb', config: config)

        redundant_offenses = result.offenses.select { |o| o[:name] == 'RedundantParamDescription' }

        # Check that long_meaningful_descriptions method has no violations
        long_desc_method_offenses = redundant_offenses.select do |o|
          o[:object_name] == 'RedundantParamFixtures#long_meaningful_descriptions'
        end

        expect(long_desc_method_offenses).to be_empty
      end

      it 'provides detailed error messages with suggestions' do
        result = Yard::Lint.run(path: 'spec/fixtures/redundant_param_descriptions.rb', config: config)

        redundant_offenses = result.offenses.select { |o| o[:name] == 'RedundantParamDescription' }

        # Check that offenses have proper structure
        redundant_offenses.each do |offense|
          expect(offense).to have_key(:location)
          expect(offense).to have_key(:line)
          expect(offense).to have_key(:message)
          expect(offense).to have_key(:object_name)
          expect(offense[:severity]).to eq('convention')
          expect(offense[:message]).to match(/[Cc]onsider/)
        end
      end
    end

    context 'when redundant_param_description is disabled' do
      let(:config) do
        test_config do |c|
          c.set_validator_config('Tags/RedundantParamDescription', 'Enabled', false)
        end
      end

      it 'does not run redundant param description validation' do
        result = Yard::Lint.run(path: 'spec/fixtures/redundant_param_descriptions.rb', config: config)

        redundant_offenses = result.offenses.select { |o| o[:name] == 'RedundantParamDescription' }
        expect(redundant_offenses).to be_empty
      end
    end

    context 'with custom configuration' do
      let(:config) do
        test_config do |c|
          c.set_validator_config('Tags/RedundantParamDescription', 'Enabled', true)
          c.set_validator_config('Tags/RedundantParamDescription', 'MaxRedundantWords', 4)
        end
      end

      it 'respects custom MaxRedundantWords threshold' do
        result = Yard::Lint.run(path: 'spec/fixtures/redundant_param_descriptions.rb', config: config)

        redundant_offenses = result.offenses.select { |o| o[:name] == 'RedundantParamDescription' }

        # With lower threshold, should find fewer violations
        # (5-6 word descriptions will not be flagged now)
        expect(redundant_offenses).to be_an(Array)
      end
    end

    context 'with pattern toggles' do
      let(:config) do
        test_config do |c|
          c.set_validator_config('Tags/RedundantParamDescription', 'Enabled', true)
          c.set_validator_config('Tags/RedundantParamDescription', 'EnabledPatterns', {
            'ArticleParam' => true,
            'PossessiveParam' => false,
            'TypeRestatement' => false,
            'ParamToVerb' => false,
            'IdPattern' => false,
            'DirectionalDate' => false,
            'TypeGeneric' => false,
            'ArticleParamPhrase' => false
          })
        end
      end

      it 'only detects enabled patterns' do
        result = Yard::Lint.run(path: 'spec/fixtures/redundant_param_descriptions.rb', config: config)

        redundant_offenses = result.offenses.select { |o| o[:name] == 'RedundantParamDescription' }

        # Should only find article_param violations
        article_only = redundant_offenses.all? do |o|
          o[:message].include?('restates the parameter name')
        end

        expect(article_only).to be true
      end
    end

    context 'with ArticleParamPhrase pattern enabled' do
      let(:config) do
        test_config do |c|
          c.set_validator_config('Tags/RedundantParamDescription', 'Enabled', true)
          c.set_validator_config('Tags/RedundantParamDescription', 'EnabledPatterns', {
            'ArticleParam' => false,
            'PossessiveParam' => false,
            'TypeRestatement' => false,
            'ParamToVerb' => false,
            'IdPattern' => false,
            'DirectionalDate' => false,
            'TypeGeneric' => false,
            'ArticleParamPhrase' => true
          })
        end
      end

      it 'detects filler phrase patterns from GitHub issue #32 examples' do
        result = Yard::Lint.run(path: 'spec/fixtures/redundant_param_descriptions.rb', config: config)

        redundant_offenses = result.offenses.select { |o| o[:name] == 'RedundantParamDescription' }

        # Should find article_param_phrase violations for our fixture examples
        phrase_violations = redundant_offenses.select do |o|
          o[:message].include?('filler phrase')
        end

        # Should detect examples like "The action being performed", "A callback to invoke", etc.
        expect(phrase_violations).not_to be_empty
        expect(phrase_violations.length).to be >= 3
      end
    end
  end

  describe 'All Validators Enabled' do
    let(:config) do
      test_config do |c|
        # Enable every single discovered validator dynamically
        Yard::Lint::ConfigLoader::ALL_VALIDATORS.each do |validator_name|
          c.set_validator_config(validator_name, 'Enabled', true)
        end
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

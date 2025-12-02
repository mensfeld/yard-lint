# frozen_string_literal: true

RSpec.describe 'BlankLineBeforeDefinition Integration' do
  let(:fixture_path) { File.expand_path('../fixtures/blank_line_before_definition.rb', __dir__) }

  let(:config) do
    test_config do |c|
      c.send(:set_validator_config, 'Documentation/BlankLineBeforeDefinition', 'Enabled', true)
    end
  end

  describe 'detecting blank lines before definitions' do
    it 'finds single blank line violations (public methods only by default)' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      single_offenses = result.offenses.select do |o|
        o[:name] == 'BlankLineBeforeDefinition' &&
          o[:message].include?('Blank line between documentation and definition')
      end

      # Should find PUBLIC only: single_blank_line, method_with_single_blank,
      # MySingleBlankClass, MySingleBlankModule
      # (protected_single_blank and private_single_blank NOT included by default)
      expect(single_offenses.size).to eq(4)
    end

    it 'finds orphaned documentation violations (public methods only by default)' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      orphaned_offenses = result.offenses.select do |o|
        o[:name] == 'BlankLineBeforeDefinition' &&
          o[:message].include?('orphaned')
      end

      # Should find PUBLIC only: two_blank_lines, three_blank_lines,
      # MyOrphanedClass, MyOrphanedModule
      # (protected_orphaned_docs and private_orphaned_docs NOT included by default)
      expect(orphaned_offenses.size).to eq(4)
    end

    it 'does not flag methods with no blank lines' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      valid_offenses = result.offenses.select do |o|
        o[:name] == 'BlankLineBeforeDefinition' &&
          (o[:message].include?('valid_no_blank_lines') ||
           o[:message].include?('another_valid_method') ||
           o[:message].include?('MyValidClass') ||
           o[:message].include?('MyValidModule'))
      end

      expect(valid_offenses).to be_empty
    end

    it 'provides helpful error messages for single blank line' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'BlankLineBeforeDefinition' &&
          o[:message].include?('single_blank_line')
      end

      expect(offense).not_to be_nil
      expect(offense[:message]).to include('Blank line between documentation and definition')
    end

    it 'provides helpful error messages for orphaned docs' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'BlankLineBeforeDefinition' &&
          o[:message].include?('two_blank_lines')
      end

      expect(offense).not_to be_nil
      expect(offense[:message]).to include('orphaned')
      expect(offense[:message]).to include('2 blank lines')
    end

    it 'includes blank line count for orphaned docs with 3 lines' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'BlankLineBeforeDefinition' &&
          o[:message].include?('three_blank_lines')
      end

      expect(offense).not_to be_nil
      expect(offense[:message]).to include('3 blank lines')
    end
  end

  describe 'configuration options' do
    context 'when only checking single blank lines' do
      let(:single_only_config) do
        test_config do |c|
          c.send(:set_validator_config, 'Documentation/BlankLineBeforeDefinition', 'Enabled', true)
          c.send(
            :set_validator_config,
            'Documentation/BlankLineBeforeDefinition',
            'EnabledPatterns',
            { 'SingleBlankLine' => true, 'OrphanedDocs' => false }
          )
        end
      end

      it 'only finds single blank line violations' do
        result = Yard::Lint.run(path: fixture_path, config: single_only_config, progress: false)

        offenses = result.offenses.select { |o| o[:name] == 'BlankLineBeforeDefinition' }

        offenses.each do |offense|
          expect(offense[:message]).not_to include('orphaned')
        end
      end
    end

    context 'when only checking orphaned docs' do
      let(:orphaned_only_config) do
        test_config do |c|
          c.send(:set_validator_config, 'Documentation/BlankLineBeforeDefinition', 'Enabled', true)
          c.send(
            :set_validator_config,
            'Documentation/BlankLineBeforeDefinition',
            'EnabledPatterns',
            { 'SingleBlankLine' => false, 'OrphanedDocs' => true }
          )
        end
      end

      it 'only finds orphaned documentation violations' do
        result = Yard::Lint.run(path: fixture_path, config: orphaned_only_config, progress: false)

        offenses = result.offenses.select { |o| o[:name] == 'BlankLineBeforeDefinition' }

        offenses.each do |offense|
          expect(offense[:message]).to include('orphaned')
        end
      end
    end

    context 'when configuring custom severities' do
      let(:custom_severity_config) do
        test_config do |c|
          c.send(:set_validator_config, 'Documentation/BlankLineBeforeDefinition', 'Enabled', true)
          c.send(:set_validator_config, 'Documentation/BlankLineBeforeDefinition', 'Severity', 'warning')
          c.send(:set_validator_config, 'Documentation/BlankLineBeforeDefinition', 'OrphanedSeverity', 'error')
        end
      end

      it 'uses configured severity for single blank line' do
        result = Yard::Lint.run(path: fixture_path, config: custom_severity_config, progress: false)

        single_offense = result.offenses.find do |o|
          o[:name] == 'BlankLineBeforeDefinition' &&
            !o[:message].include?('orphaned')
        end

        expect(single_offense[:severity]).to eq('warning')
      end

      it 'uses OrphanedSeverity for orphaned docs' do
        result = Yard::Lint.run(path: fixture_path, config: custom_severity_config, progress: false)

        orphaned_offense = result.offenses.find do |o|
          o[:name] == 'BlankLineBeforeDefinition' &&
            o[:message].include?('orphaned')
        end

        expect(orphaned_offense[:severity]).to eq('error')
      end
    end
  end

  describe 'when disabled' do
    it 'does not run validation' do
      disabled_config = test_config do |c|
        c.send(:set_validator_config, 'Documentation/BlankLineBeforeDefinition', 'Enabled', false)
      end

      result = Yard::Lint.run(path: fixture_path, config: disabled_config, progress: false)

      blank_line_offenses = result.offenses.select { |o| o[:name] == 'BlankLineBeforeDefinition' }
      expect(blank_line_offenses).to be_empty
    end
  end

  describe 'valid documentation is not flagged' do
    it 'does not flag properly formatted docs' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      valid_offenses = result.offenses.select do |o|
        o[:name] == 'BlankLineBeforeDefinition' &&
          (o[:message].include?('valid_no_blank_lines') ||
           o[:message].include?('another_valid_method'))
      end

      expect(valid_offenses).to be_empty
    end
  end

  describe 'visibility configuration with YardOptions' do
    context 'when checking private methods with --private' do
      let(:private_config) do
        test_config do |c|
          c.send(:set_validator_config, 'Documentation/BlankLineBeforeDefinition', 'Enabled', true)
          c.send(
            :set_validator_config,
            'Documentation/BlankLineBeforeDefinition',
            'YardOptions',
            ['--private']
          )
        end
      end

      it 'finds violations in private methods' do
        result = Yard::Lint.run(path: fixture_path, config: private_config, progress: false)

        offenses = result.offenses.select { |o| o[:name] == 'BlankLineBeforeDefinition' }
        offense_methods = offenses.map { |o| o[:object_name] }

        # Should find private methods with blank line issues
        expect(offense_methods.any? { |m| m&.include?('private_single_blank') }).to be true
        expect(offense_methods.any? { |m| m&.include?('private_orphaned_docs') }).to be true
      end

      it 'still finds public method violations' do
        result = Yard::Lint.run(path: fixture_path, config: private_config, progress: false)

        offenses = result.offenses.select { |o| o[:name] == 'BlankLineBeforeDefinition' }
        offense_methods = offenses.map { |o| o[:object_name] }

        expect(offense_methods.any? { |m| m&.include?('single_blank_line') }).to be true
      end
    end

    context 'when checking protected methods with --protected' do
      let(:protected_config) do
        test_config do |c|
          c.send(:set_validator_config, 'Documentation/BlankLineBeforeDefinition', 'Enabled', true)
          c.send(
            :set_validator_config,
            'Documentation/BlankLineBeforeDefinition',
            'YardOptions',
            ['--protected']
          )
        end
      end

      it 'finds violations in protected methods' do
        result = Yard::Lint.run(path: fixture_path, config: protected_config, progress: false)

        offenses = result.offenses.select { |o| o[:name] == 'BlankLineBeforeDefinition' }
        offense_methods = offenses.map { |o| o[:object_name] }

        # Should find protected methods with blank line issues
        expect(offense_methods.any? { |m| m&.include?('protected_single_blank') }).to be true
        expect(offense_methods.any? { |m| m&.include?('protected_orphaned_docs') }).to be true
      end
    end

    context 'when checking all visibility levels with --private --protected' do
      let(:all_visibility_config) do
        test_config do |c|
          c.send(:set_validator_config, 'Documentation/BlankLineBeforeDefinition', 'Enabled', true)
          c.send(
            :set_validator_config,
            'Documentation/BlankLineBeforeDefinition',
            'YardOptions',
            ['--private', '--protected']
          )
        end
      end

      it 'finds violations across all visibility levels' do
        result = Yard::Lint.run(path: fixture_path, config: all_visibility_config, progress: false)

        offenses = result.offenses.select { |o| o[:name] == 'BlankLineBeforeDefinition' }
        offense_methods = offenses.map { |o| o[:object_name] }

        # Should find public, protected, AND private methods
        expect(offense_methods.any? { |m| m&.include?('single_blank_line') }).to be true
        expect(offense_methods.any? { |m| m&.include?('protected_single_blank') }).to be true
        expect(offense_methods.any? { |m| m&.include?('private_single_blank') }).to be true
        expect(offense_methods.any? { |m| m&.include?('protected_orphaned_docs') }).to be true
        expect(offense_methods.any? { |m| m&.include?('private_orphaned_docs') }).to be true
      end

      it 'includes more violations than public-only mode' do
        public_result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
        all_result = Yard::Lint.run(path: fixture_path, config: all_visibility_config, progress: false)

        public_offenses = public_result.offenses.select { |o| o[:name] == 'BlankLineBeforeDefinition' }
        all_offenses = all_result.offenses.select { |o| o[:name] == 'BlankLineBeforeDefinition' }

        # All visibility should have more offenses than public only
        expect(all_offenses.size).to be > public_offenses.size
      end
    end

    context 'when global YardOptions has --private but validator overrides with empty' do
      it 'respects validator-specific YardOptions over global' do
        files = [File.expand_path(fixture_path)]

        override_config = Yard::Lint::Config.new(
          {
            'AllValidators' => {
              'YardOptions' => ['--private'],
              'Exclude' => []
            },
            'Documentation/BlankLineBeforeDefinition' => {
              'Enabled' => true,
              'YardOptions' => [] # Override to public only
            }
          }
        )

        runner = Yard::Lint::Runner.new(files, override_config)
        result = runner.run

        offenses = result.offenses.select { |o| o[:name] == 'BlankLineBeforeDefinition' }
        offense_methods = offenses.map { |o| o[:object_name] }

        # Should NOT see private methods (validator-specific empty YardOptions)
        expect(offense_methods.none? { |m| m&.include?('private_single_blank') }).to be true
        expect(offense_methods.none? { |m| m&.include?('private_orphaned_docs') }).to be true
      end
    end

    context 'when validator inherits global --private YardOptions' do
      it 'sees private methods when inheriting from AllValidators' do
        files = [File.expand_path(fixture_path)]

        inherit_config = Yard::Lint::Config.new(
          {
            'AllValidators' => {
              'YardOptions' => ['--private'],
              'Exclude' => []
            },
            'Documentation/BlankLineBeforeDefinition' => {
              'Enabled' => true
              # No YardOptions - inherits from AllValidators
            }
          }
        )

        runner = Yard::Lint::Runner.new(files, inherit_config)
        result = runner.run

        offenses = result.offenses.select { |o| o[:name] == 'BlankLineBeforeDefinition' }
        offense_methods = offenses.map { |o| o[:object_name] }

        # Should see private methods (inherited --private from AllValidators)
        expect(offense_methods.any? { |m| m&.include?('private_single_blank') }).to be true
        expect(offense_methods.any? { |m| m&.include?('private_orphaned_docs') }).to be true
      end
    end
  end

  describe 'does not flag valid private/protected methods' do
    let(:all_visibility_config) do
      test_config do |c|
        c.send(:set_validator_config, 'Documentation/BlankLineBeforeDefinition', 'Enabled', true)
        c.send(:set_validator_config, 'Documentation/BlankLineBeforeDefinition', 'YardOptions',
               ['--private', '--protected'])
      end
    end

    it 'does not flag private methods with no blank lines' do
      result = Yard::Lint.run(path: fixture_path, config: all_visibility_config, progress: false)

      valid_offenses = result.offenses.select do |o|
        o[:name] == 'BlankLineBeforeDefinition' &&
          o[:object_name]&.include?('private_valid_method')
      end

      expect(valid_offenses).to be_empty
    end

    it 'does not flag protected methods with no blank lines' do
      result = Yard::Lint.run(path: fixture_path, config: all_visibility_config, progress: false)

      valid_offenses = result.offenses.select do |o|
        o[:name] == 'BlankLineBeforeDefinition' &&
          o[:object_name]&.include?('protected_valid_method')
      end

      expect(valid_offenses).to be_empty
    end
  end
end

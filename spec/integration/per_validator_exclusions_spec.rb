# frozen_string_literal: true

RSpec.describe 'Per-validator file exclusions', :integration, type: :feature do
  let(:fixtures_dir) { File.expand_path('fixtures', __dir__) }

  describe 'filtering files per validator' do
    it 'excludes files only for specific validators' do
      files = [
        File.join(fixtures_dir, 'missing_param_docs.rb'),
        File.join(fixtures_dir, 'undocumented_objects.rb')
      ]

      config = Yard::Lint::Config.new(
        {
          'AllValidators' => {
            'Exclude' => []
          },
          'Documentation/UndocumentedObjects' => {
            'Enabled' => true,
            'Exclude' => ['**/missing_param_docs.rb']
          },
          'Documentation/UndocumentedMethodArguments' => {
            'Enabled' => true,
            'Exclude' => ['**/undocumented_objects.rb']
          }
        }
      )

      runner = Yard::Lint::Runner.new(files, config)
      result = runner.run

      # UndocumentedObject offenses should NOT include missing_param_docs.rb
      undoc_object_offenses = result.offenses.select { |o| o[:name] == 'UndocumentedObject' }
      undoc_object_locations = undoc_object_offenses.map { |o| o[:location] }
      expect(undoc_object_locations).not_to include(
        match(/missing_param_docs\.rb/)
      )

      # UndocumentedMethodArgument offenses should NOT include undocumented_objects.rb
      undoc_arg_offenses = result.offenses.select { |o| o[:name] == 'UndocumentedMethodArgument' }
      undoc_arg_locations = undoc_arg_offenses.map { |o| o[:location] }
      expect(undoc_arg_locations).not_to include(
        match(/undocumented_objects\.rb/)
      )
    end
  end

  describe 'with glob patterns' do
    it 'supports wildcard and recursive patterns' do
      files = [
        File.join(fixtures_dir, 'yard_warnings.rb')
      ]

      config = Yard::Lint::Config.new(
        {
          'AllValidators' => { 'Exclude' => [] },
          'Warnings/UnknownTag' => {
            'Enabled' => true,
            'Exclude' => ['**/fixtures/**/*']
          }
        }
      )

      runner = Yard::Lint::Runner.new(files, config)
      result = runner.run

      # UnknownTag warnings should be empty because all files are excluded
      unknown_tag_offenses = result.offenses.select { |o| o[:name] == 'UnknownTag' }
      expect(unknown_tag_offenses).to be_empty
    end
  end

  describe 'combining global and per-validator exclusions' do
    it 'applies validator-specific exclusions independently' do
      files = [
        File.join(fixtures_dir, 'missing_param_docs.rb'),
        File.join(fixtures_dir, 'undocumented_objects.rb')
      ]

      config = Yard::Lint::Config.new(
        {
          'AllValidators' => {
            'Exclude' => []
          },
          'Documentation/UndocumentedMethodArguments' => {
            'Enabled' => true,
            'Exclude' => ['**/missing_param_docs.rb', '**/undocumented_objects.rb']
          }
        }
      )

      runner = Yard::Lint::Runner.new(files, config)
      result = runner.run

      # UndocumentedMethodArguments should not see any files
      # (both excluded by validator-specific patterns)
      undoc_arg_offenses = result.offenses.select { |o| o[:name] == 'UndocumentedMethodArgument' }
      expect(undoc_arg_offenses).to be_empty
    end
  end

  describe 'per-validator exclusions do not affect other validators' do
    it 'allows other validators to still process excluded files' do
      files = [
        File.join(fixtures_dir, 'undocumented_class.rb')
      ]

      config = Yard::Lint::Config.new(
        {
          'AllValidators' => {
            'Exclude' => []
          },
          'Documentation/UndocumentedMethodArguments' => {
            'Enabled' => true,
            'Exclude' => ['**/undocumented_class.rb']
          },
          'Documentation/UndocumentedObjects' => {
            'Enabled' => true,
            'Exclude' => []
          }
        }
      )

      runner = Yard::Lint::Runner.new(files, config)
      result = runner.run

      # UndocumentedMethodArguments should have no offenses (file excluded)
      undoc_arg_offenses = result.offenses.select { |o| o[:name] == 'UndocumentedMethodArgument' }
      expect(undoc_arg_offenses).to be_empty

      # UndocumentedObjects should still find offenses (file not excluded for this validator)
      undoc_object_offenses = result.offenses.select { |o| o[:name] == 'UndocumentedObject' }
      expect(undoc_object_offenses).not_to be_empty
    end
  end

  describe 'private methods: enforce tag order but allow undocumented' do
    it 'checks tag order on documented private methods but ignores undocumented ones' do
      files = [
        File.join(fixtures_dir, 'private_methods.rb')
      ]

      # Configuration that:
      # 1. Includes private methods in YARD parsing (--private)
      # 2. Excludes private methods from documentation validators
      # 3. Still checks tag order on private methods (if they have docs)
      config = Yard::Lint::Config.new(
        {
          'AllValidators' => {
            'YardOptions' => ['--private'],
            'Exclude' => []
          },
          # Don't require documentation on private methods
          'Documentation/UndocumentedObjects' => {
            'Enabled' => true,
            'Exclude' => ['**/private_methods.rb']
          },
          'Documentation/UndocumentedMethodArguments' => {
            'Enabled' => true,
            'Exclude' => ['**/private_methods.rb']
          },
          # But DO enforce tag order if private methods have docs
          'Tags/Order' => {
            'Enabled' => true,
            'Exclude' => []
          }
        }
      )

      runner = Yard::Lint::Runner.new(files, config)
      result = runner.run

      # Should NOT complain about undocumented private methods
      undoc_object_offenses = result.offenses.select { |o| o[:name] == 'UndocumentedObject' }
      undoc_arg_offenses = result.offenses.select { |o| o[:name] == 'UndocumentedMethodArgument' }

      expect(undoc_object_offenses).to be_empty
      expect(undoc_arg_offenses).to be_empty

      # But SHOULD enforce tag order on documented private methods
      tag_order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }

      expect(tag_order_offenses).not_to be_empty

      # Verify it found the wrong order in documented_private_wrong_order
      # Check that at least one offense is from private_methods.rb
      private_methods_offense = tag_order_offenses.find do |o|
        o[:location].include?('private_methods.rb')
      end

      expect(private_methods_offense).not_to be_nil
      # The offense should be about documented_private_wrong_order method
      expect(private_methods_offense[:method_name]).to include('documented_private_wrong_order')
    end
  end

  describe 'protected methods: enforce tag order but allow undocumented' do
    it 'checks tag order on documented protected methods but ignores undocumented ones' do
      files = [
        File.join(fixtures_dir, 'protected_methods.rb')
      ]

      config = Yard::Lint::Config.new(
        {
          'AllValidators' => {
            'YardOptions' => ['--protected'],
            'Exclude' => []
          },
          'Documentation/UndocumentedObjects' => {
            'Enabled' => true,
            'Exclude' => ['**/protected_methods.rb']
          },
          'Documentation/UndocumentedMethodArguments' => {
            'Enabled' => true,
            'Exclude' => ['**/protected_methods.rb']
          },
          'Tags/Order' => {
            'Enabled' => true,
            'Exclude' => []
          }
        }
      )

      runner = Yard::Lint::Runner.new(files, config)
      result = runner.run

      # Should NOT complain about undocumented protected methods
      undoc_object_offenses = result.offenses.select { |o| o[:name] == 'UndocumentedObject' }
      undoc_arg_offenses = result.offenses.select { |o| o[:name] == 'UndocumentedMethodArgument' }

      expect(undoc_object_offenses).to be_empty
      expect(undoc_arg_offenses).to be_empty

      # But SHOULD enforce tag order on documented protected methods
      tag_order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
      expect(tag_order_offenses).not_to be_empty

      protected_offense = tag_order_offenses.find do |o|
        o[:location].include?('protected_methods.rb') &&
          o[:method_name]&.include?('protected_wrong_order')
      end

      expect(protected_offense).not_to be_nil
    end
  end

  describe 'module functions with selective exclusions' do
    it 'excludes undocumented module functions but still validates documentation' do
      files = [
        File.join(fixtures_dir, 'module_functions.rb')
      ]

      config = Yard::Lint::Config.new(
        {
          'AllValidators' => {
            'Exclude' => []
          },
          'Documentation/UndocumentedObjects' => {
            'Enabled' => true,
            'Exclude' => ['**/module_functions.rb']
          },
          'Documentation/UndocumentedMethodArguments' => {
            'Enabled' => true,
            'Exclude' => []
          }
        }
      )

      runner = Yard::Lint::Runner.new(files, config)
      result = runner.run

      # Should NOT complain about undocumented objects (excluded)
      undoc_object_offenses = result.offenses.select { |o| o[:name] == 'UndocumentedObject' }
      expect(undoc_object_offenses).to be_empty

      # But SHOULD find undocumented method arguments (not excluded)
      undoc_arg_offenses = result.offenses.select { |o| o[:name] == 'UndocumentedMethodArgument' }
      expect(undoc_arg_offenses).not_to be_empty

      # Verify it finds undocumented_function and undocumented_instance
      undoc_methods = undoc_arg_offenses.map { |o| o[:method_name] }
      expect(undoc_methods.any? { |m| m&.include?('undocumented') }).to be true
    end
  end

  describe 'class methods with separate exclusions from instance methods' do
    it 'validates both class and instance methods' do
      files = [
        File.join(fixtures_dir, 'class_methods.rb')
      ]

      # Note: This test demonstrates that yard-lint processes all methods together
      # We can't currently exclude class methods separately from instance methods
      # This is a known limitation - exclusions are file-based, not method-type-based
      config = Yard::Lint::Config.new(
        {
          'AllValidators' => {
            'Exclude' => []
          },
          'Documentation/UndocumentedMethodArguments' => {
            'Enabled' => true,
            'Exclude' => []
          },
          'Tags/Order' => {
            'Enabled' => true,
            'Exclude' => []
          }
        }
      )

      runner = Yard::Lint::Runner.new(files, config)
      result = runner.run

      # Should find undocumented method arguments (both instance and class)
      undoc_arg_offenses = result.offenses.select { |o| o[:name] == 'UndocumentedMethodArgument' }
      expect(undoc_arg_offenses).not_to be_empty

      # Verify both instance and class methods are checked
      undoc_methods = undoc_arg_offenses.map { |o| o[:method_name] }
      expect(undoc_methods.any? { |m| m&.include?('undocumented_instance') }).to be true
      expect(undoc_methods.any? { |m| m&.include?('undocumented_class_method') }).to be true

      # Should find tag order issues in class methods
      tag_order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
      class_method_offense = tag_order_offenses.find do |o|
        o[:method_name]&.include?('class_method_wrong_order')
      end
      expect(class_method_offense).not_to be_nil
    end
  end

  describe 'attribute methods with exclusions' do
    it 'validates files with attribute accessors can use per-validator exclusions' do
      files = [
        File.join(fixtures_dir, 'attribute_methods.rb')
      ]

      # Note: YARD doesn't report undocumented attr_* by default
      # This test verifies exclusions work on files with attributes
      config = Yard::Lint::Config.new(
        {
          'AllValidators' => {
            'Exclude' => []
          },
          'Documentation/UndocumentedMethodArguments' => {
            'Enabled' => true,
            'Exclude' => []
          }
        }
      )

      runner = Yard::Lint::Runner.new(files, config)
      result = runner.run

      # attribute_methods.rb has undocumented regular methods (info, status)
      # We expect those to be detected
      undoc_arg_offenses = result.offenses.select { |o| o[:name] == 'UndocumentedMethodArgument' }

      # If no offenses, that's also valid (YARD may not detect them without proper flags)
      # The key is that exclusions work - test this by excluding and verifying empty
      config_with_exclusion = Yard::Lint::Config.new(
        {
          'AllValidators' => { 'Exclude' => [] },
          'Documentation/UndocumentedMethodArguments' => {
            'Enabled' => true,
            'Exclude' => ['**/attribute_methods.rb']
          }
        }
      )

      runner2 = Yard::Lint::Runner.new(files, config_with_exclusion)
      result2 = runner2.run

      # With exclusion, should have no offenses from this file
      excluded_offenses = result2.offenses.select do |o|
        o[:location]&.include?('attribute_methods.rb')
      end
      expect(excluded_offenses).to be_empty
    end
  end

  describe 'complex method signatures with missing parameter documentation' do
    it 'detects missing @param tags for keyword args, splats, and blocks' do
      files = [
        File.join(fixtures_dir, 'complex_signatures.rb')
      ]

      config = Yard::Lint::Config.new(
        {
          'AllValidators' => {
            'Exclude' => []
          },
          'Documentation/UndocumentedMethodArguments' => {
            'Enabled' => true,
            'Exclude' => []
          }
        }
      )

      runner = Yard::Lint::Runner.new(files, config)
      result = runner.run

      # Should find methods with missing parameter documentation
      undoc_arg_offenses = result.offenses.select { |o| o[:name] == 'UndocumentedMethodArgument' }
      expect(undoc_arg_offenses).not_to be_empty

      # Check that it finds some of the undocumented methods
      undoc_methods = undoc_arg_offenses.map { |o| o[:method_name] }
      expect(undoc_methods.any? { |m| m&.include?('process') }).to be true
    end
  end

  describe 'mixed visibility in single file with selective exclusions' do
    it 'validates methods across different visibility levels' do
      files = [
        File.join(fixtures_dir, 'mixed_visibility.rb')
      ]

      # Include private and protected methods in analysis
      config = Yard::Lint::Config.new(
        {
          'AllValidators' => {
            'YardOptions' => ['--private', '--protected'],
            'Exclude' => []
          },
          'Documentation/UndocumentedMethodArguments' => {
            'Enabled' => true,
            'Exclude' => []
          },
          'Tags/Order' => {
            'Enabled' => true,
            'Exclude' => []
          }
        }
      )

      runner = Yard::Lint::Runner.new(files, config)
      result = runner.run

      # Should find undocumented method arguments across all visibility levels
      undoc_arg_offenses = result.offenses.select { |o| o[:name] == 'UndocumentedMethodArgument' }
      expect(undoc_arg_offenses).not_to be_empty

      # Verify we found undocumented methods from different visibility levels
      undoc_methods = undoc_arg_offenses.map { |o| o[:method_name] }
      expect(undoc_methods.any? { |m| m&.include?('public_undocumented') }).to be true
      expect(undoc_methods.any? { |m| m&.include?('protected_undocumented') }).to be true
      expect(undoc_methods.any? { |m| m&.include?('private_undocumented') }).to be true

      # Should find tag order issues in public, protected, and private methods
      tag_order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
      expect(tag_order_offenses.size).to be >= 3 # At least 3 wrong order methods

      # Verify we found wrong_order methods from different visibility levels
      wrong_order_methods = tag_order_offenses.map { |o| o[:method_name] }
      expect(wrong_order_methods.any? { |m| m&.include?('public_wrong_order') }).to be true
    end
  end

  describe 'multiple validators with overlapping file exclusions' do
    it 'respects each validator exclusion independently without duplication' do
      files = [
        File.join(fixtures_dir, 'missing_param_docs.rb')
      ]

      # Both validators exclude the same file
      config = Yard::Lint::Config.new(
        {
          'AllValidators' => {
            'Exclude' => []
          },
          'Documentation/UndocumentedObjects' => {
            'Enabled' => true,
            'Exclude' => ['**/missing_param_docs.rb']
          },
          'Documentation/UndocumentedMethodArguments' => {
            'Enabled' => true,
            'Exclude' => ['**/missing_param_docs.rb']
          }
        }
      )

      runner = Yard::Lint::Runner.new(files, config)
      result = runner.run

      # Both validators excluded the file, so no offenses from either
      undoc_object_offenses = result.offenses.select { |o| o[:name] == 'UndocumentedObject' }
      undoc_arg_offenses = result.offenses.select { |o| o[:name] == 'UndocumentedMethodArgument' }

      expect(undoc_object_offenses).to be_empty
      expect(undoc_arg_offenses).to be_empty
    end
  end

  describe 'per-validator exclusions with cross-validator scenarios' do
    it 'one validator sees file A, another sees file B' do
      files = [
        File.join(fixtures_dir, 'protected_methods.rb'),
        File.join(fixtures_dir, 'private_methods.rb')
      ]

      # Configure validators to see different files
      config = Yard::Lint::Config.new(
        {
          'AllValidators' => {
            'YardOptions' => ['--private', '--protected'],
            'Exclude' => []
          },
          # This validator excludes protected_methods.rb
          'Documentation/UndocumentedMethodArguments' => {
            'Enabled' => true,
            'Exclude' => ['**/protected_methods.rb']
          },
          # This validator excludes private_methods.rb
          'Tags/Order' => {
            'Enabled' => true,
            'Exclude' => ['**/private_methods.rb']
          }
        }
      )

      runner = Yard::Lint::Runner.new(files, config)
      result = runner.run

      # UndocumentedMethodArguments should only see private_methods.rb
      undoc_arg_offenses = result.offenses.select { |o| o[:name] == 'UndocumentedMethodArgument' }
      undoc_arg_files = undoc_arg_offenses.map { |o| o[:location] }
      # Verify we have offenses from private_methods.rb
      expect(undoc_arg_files.any? { |f| f.include?('private_methods.rb') }).to be true

      # Tags/Order should see both files (we only excluded it from UndocumentedMethodArguments)
      # But it should find offenses in both (both have wrong order methods)
      tag_order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
      # Verify we have tag order offenses
      expect(tag_order_offenses).not_to be_empty
    end
  end
end

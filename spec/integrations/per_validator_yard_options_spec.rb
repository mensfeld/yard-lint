# frozen_string_literal: true

RSpec.describe 'Per-validator YardOptions configuration', :integration, type: :feature do
  let(:fixtures_dir) { File.expand_path('fixtures', __dir__) }

  describe 'validator-specific YardOptions override global options' do
    context 'when global has --private but validator has empty YardOptions' do
      it 'does not see private methods for the validator with empty YardOptions' do
        files = [File.join(fixtures_dir, 'private_methods.rb')]

        config = Yard::Lint::Config.new(
          {
            'AllValidators' => {
              'YardOptions' => ['--private'],
              'Exclude' => []
            },
            # This validator should NOT see private methods (empty YardOptions)
            'Documentation/UndocumentedObjects' => {
              'Enabled' => true,
              'YardOptions' => []
            },
            # This validator SHOULD see private methods (inherits global)
            'Tags/Order' => {
              'Enabled' => true
            }
          }
        )

        runner = Yard::Lint::Runner.new(files, config)
        result = runner.run

        # UndocumentedObjects should NOT report private methods (visibility=public due to empty YardOptions)
        undoc_offenses = result.offenses.select { |o| o[:name] == 'UndocumentedObject' }
        private_undoc = undoc_offenses.select { |o| o[:element]&.include?('undocumented_private') }
        expect(private_undoc).to be_empty

        # Tags/Order SHOULD see private methods and report wrong order
        tag_order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
        private_order = tag_order_offenses.select { |o| o[:method_name]&.include?('documented_private_wrong_order') }
        expect(private_order).not_to be_empty
      end
    end

    context 'when global has no --private but validator has --private' do
      it 'sees private methods only for the validator with --private YardOptions' do
        files = [File.join(fixtures_dir, 'private_methods.rb')]

        config = Yard::Lint::Config.new(
          {
            'AllValidators' => {
              'YardOptions' => [],
              'Exclude' => []
            },
            # This validator should NOT see private methods (inherits empty global)
            'Documentation/UndocumentedObjects' => {
              'Enabled' => true
            },
            # This validator SHOULD see private methods (has --private)
            'Tags/Order' => {
              'Enabled' => true,
              'YardOptions' => ['--private']
            }
          }
        )

        runner = Yard::Lint::Runner.new(files, config)
        result = runner.run

        # UndocumentedObjects should NOT report private methods (visibility=public)
        undoc_offenses = result.offenses.select { |o| o[:name] == 'UndocumentedObject' }
        private_undoc = undoc_offenses.select { |o| o[:element]&.include?('private') }
        expect(private_undoc).to be_empty

        # Tags/Order SHOULD see private methods due to its own --private YardOption
        tag_order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
        private_order = tag_order_offenses.select { |o| o[:method_name]&.include?('documented_private_wrong_order') }
        expect(private_order).not_to be_empty
      end
    end
  end

  describe 'different validators with different visibility settings' do
    it 'allows fine-grained control over which validators see which visibility levels' do
      files = [File.join(fixtures_dir, 'mixed_visibility.rb')]

      config = Yard::Lint::Config.new(
        {
          'AllValidators' => {
            'YardOptions' => ['--private', '--protected'],
            'Exclude' => []
          },
          # Documentation validators should only check public methods
          'Documentation/UndocumentedMethodArguments' => {
            'Enabled' => true,
            'YardOptions' => []
          },
          # Tag validators should check all visibility levels (inherits global)
          'Tags/Order' => {
            'Enabled' => true
          }
        }
      )

      runner = Yard::Lint::Runner.new(files, config)
      result = runner.run

      # UndocumentedMethodArguments should only see public methods (YardOptions: [])
      undoc_arg_offenses = result.offenses.select { |o| o[:name] == 'UndocumentedMethodArgument' }
      undoc_methods = undoc_arg_offenses.map { |o| o[:method_name] }

      # Should see public_undocumented (has no @param tags)
      expect(undoc_methods.any? { |m| m&.include?('public_undocumented') }).to be true
      # Should NOT see protected_undocumented or private_undocumented (public visibility only)
      expect(undoc_methods.none? { |m| m&.include?('protected_undocumented') }).to be true
      expect(undoc_methods.none? { |m| m&.include?('private_undocumented') }).to be true

      # Tags/Order should see ALL visibility levels (inherits --private --protected)
      tag_order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
      wrong_order_methods = tag_order_offenses.map { |o| o[:method_name] }

      # Should see wrong_order methods from all visibility levels
      expect(wrong_order_methods.any? { |m| m&.include?('public_wrong_order') }).to be true
      expect(wrong_order_methods.any? { |m| m&.include?('protected_wrong_order') }).to be true
      expect(wrong_order_methods.any? { |m| m&.include?('private_wrong_order') }).to be true
    end
  end

  describe 'protected visibility configuration' do
    it 'treats --protected as including all non-public visibility levels' do
      # Note: YARD treats both --protected and --private as "include non-public"
      # So --protected alone will include private methods as well
      files = [File.join(fixtures_dir, 'mixed_visibility.rb')]

      config = Yard::Lint::Config.new(
        {
          'AllValidators' => {
            'YardOptions' => [],
            'Exclude' => []
          },
          # This validator has --protected, which enables all visibility
          'Tags/Order' => {
            'Enabled' => true,
            'YardOptions' => ['--protected']
          },
          # This validator has no explicit YardOptions and inherits empty global
          'Documentation/UndocumentedMethodArguments' => {
            'Enabled' => true
          }
        }
      )

      runner = Yard::Lint::Runner.new(files, config)
      result = runner.run

      # Tags/Order should see all visibility levels (--protected enables :all)
      tag_order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
      wrong_order_methods = tag_order_offenses.map { |o| o[:method_name] }

      expect(wrong_order_methods.any? { |m| m&.include?('public_wrong_order') }).to be true
      expect(wrong_order_methods.any? { |m| m&.include?('protected_wrong_order') }).to be true
      expect(wrong_order_methods.any? { |m| m&.include?('private_wrong_order') }).to be true

      # UndocumentedMethodArguments should only see public (inherits empty global)
      undoc_arg_offenses = result.offenses.select { |o| o[:name] == 'UndocumentedMethodArgument' }
      undoc_methods = undoc_arg_offenses.map { |o| o[:method_name] }
      expect(undoc_methods.any? { |m| m&.include?('public_undocumented') }).to be true
      expect(undoc_methods.none? { |m| m&.include?('protected_undocumented') }).to be true
      expect(undoc_methods.none? { |m| m&.include?('private_undocumented') }).to be true
    end
  end

  describe 'multiple validators each with different YardOptions' do
    it 'each validator respects its own YardOptions independently' do
      files = [File.join(fixtures_dir, 'mixed_visibility.rb')]

      config = Yard::Lint::Config.new(
        {
          'AllValidators' => {
            'YardOptions' => [],
            'Exclude' => []
          },
          # Validator A: public only (explicit empty)
          'Documentation/UndocumentedMethodArguments' => {
            'Enabled' => true,
            'YardOptions' => []
          },
          # Validator B: all visibility levels (--private)
          'Tags/Order' => {
            'Enabled' => true,
            'YardOptions' => ['--private']
          }
        }
      )

      runner = Yard::Lint::Runner.new(files, config)
      result = runner.run

      # Validator A (UndocumentedMethodArguments): public only
      undoc_arg_offenses = result.offenses.select { |o| o[:name] == 'UndocumentedMethodArgument' }
      undoc_arg_methods = undoc_arg_offenses.map { |o| o[:method_name] }
      expect(undoc_arg_methods.any? { |m| m&.include?('public_undocumented') }).to be true
      expect(undoc_arg_methods.none? { |m| m&.include?('protected_undocumented') }).to be true
      expect(undoc_arg_methods.none? { |m| m&.include?('private_undocumented') }).to be true

      # Validator B (Tags/Order): all visibility
      tag_order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
      wrong_order_methods = tag_order_offenses.map { |o| o[:method_name] }
      expect(wrong_order_methods.any? { |m| m&.include?('public_wrong_order') }).to be true
      expect(wrong_order_methods.any? { |m| m&.include?('protected_wrong_order') }).to be true
      expect(wrong_order_methods.any? { |m| m&.include?('private_wrong_order') }).to be true
    end
  end

  describe 'YardOptions with Tags validators' do
    context 'with InvalidTypes validator' do
      it 'respects per-validator YardOptions for type checking' do
        files = [File.join(fixtures_dir, 'private_methods.rb')]

        # Test that InvalidTypes can be configured to only check public methods
        config = Yard::Lint::Config.new(
          {
            'AllValidators' => {
              'YardOptions' => ['--private'],
              'Exclude' => []
            },
            'Tags/InvalidTypes' => {
              'Enabled' => true,
              'YardOptions' => [] # Only check public methods
            },
            'Tags/Order' => {
              'Enabled' => true
              # Inherits global --private
            }
          }
        )

        runner = Yard::Lint::Runner.new(files, config)
        result = runner.run

        # Tags/Order should see private methods
        tag_order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
        expect(tag_order_offenses.any? { |o| o[:method_name]&.include?('private') }).to be true
      end
    end

    context 'with TypeSyntax validator' do
      it 'respects per-validator YardOptions for syntax checking' do
        files = [File.join(fixtures_dir, 'private_methods.rb')]

        config = Yard::Lint::Config.new(
          {
            'AllValidators' => {
              'YardOptions' => ['--private'],
              'Exclude' => []
            },
            'Tags/TypeSyntax' => {
              'Enabled' => true,
              'YardOptions' => [] # Only check public methods
            }
          }
        )

        runner = Yard::Lint::Runner.new(files, config)
        result = runner.run

        # TypeSyntax should only see public methods due to its empty YardOptions
        type_syntax_offenses = result.offenses.select { |o| o[:name] == 'InvalidTypeSyntax' }
        # No private method type syntax issues should be reported
        private_offenses = type_syntax_offenses.select { |o| o[:method_name]&.include?('private') }
        expect(private_offenses).to be_empty
      end
    end
  end

  describe 'YardOptions inheritance and fallback behavior' do
    it 'validators without explicit YardOptions inherit from AllValidators' do
      files = [File.join(fixtures_dir, 'private_methods.rb')]

      config = Yard::Lint::Config.new(
        {
          'AllValidators' => {
            'YardOptions' => ['--private'],
            'Exclude' => []
          },
          # No YardOptions specified - should inherit --private from AllValidators
          'Tags/Order' => {
            'Enabled' => true
          }
        }
      )

      runner = Yard::Lint::Runner.new(files, config)
      result = runner.run

      # Tags/Order should see private methods (inherited from AllValidators)
      tag_order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
      private_order = tag_order_offenses.select { |o| o[:method_name]&.include?('documented_private_wrong_order') }
      expect(private_order).not_to be_empty
    end

    it 'explicit empty YardOptions overrides global non-empty YardOptions' do
      files = [File.join(fixtures_dir, 'private_methods.rb')]

      config = Yard::Lint::Config.new(
        {
          'AllValidators' => {
            'YardOptions' => ['--private'],
            'Exclude' => []
          },
          # Explicit empty array - should NOT inherit --private
          'Tags/Order' => {
            'Enabled' => true,
            'YardOptions' => []
          }
        }
      )

      runner = Yard::Lint::Runner.new(files, config)
      result = runner.run

      # Tags/Order should NOT see private methods (explicit empty YardOptions)
      tag_order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
      private_order = tag_order_offenses.select { |o| o[:method_name]&.include?('documented_private_wrong_order') }
      expect(private_order).to be_empty

      # Should still see public method issues
      public_order = tag_order_offenses.select { |o| o[:method_name]&.include?('public') }
      # private_methods.rb only has public_method which has correct docs
      expect(public_order).to be_empty
    end
  end

  describe 'regression test: config.validator_yard_options is used for visibility' do
    it 'uses validator_yard_options method not all_validators directly' do
      # This test verifies the fix from PR #41 is working
      # The bug was that determine_visibility used all_validators['YardOptions'] directly
      # instead of calling validator_yard_options which respects per-validator settings

      files = [File.join(fixtures_dir, 'private_constants.rb')]

      config = Yard::Lint::Config.new(
        {
          'AllValidators' => {
            'YardOptions' => ['--private'],
            'Exclude' => []
          },
          'Documentation/UndocumentedObjects' => {
            'Enabled' => true,
            'YardOptions' => [] # Should NOT see private constants
          },
          'Tags/Order' => {
            'Enabled' => true
            # Inherits --private, SHOULD see private methods
          }
        }
      )

      runner = Yard::Lint::Runner.new(files, config)
      result = runner.run

      # The private constant RED should NOT trigger UndocumentedObject
      # because UndocumentedObjects has YardOptions: [] (public only)
      undoc_offenses = result.offenses.select { |o| o[:name] == 'UndocumentedObject' }
      constant_offenses = undoc_offenses.select { |o| o[:element]&.include?('RED') }
      expect(constant_offenses).to be_empty

      # The colorize private method SHOULD trigger InvalidTagOrder
      # because Tags/Order inherits --private from AllValidators
      tag_order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
      colorize_offense = tag_order_offenses.find { |o| o[:method_name] == 'colorize' }
      expect(colorize_offense).not_to be_nil
    end
  end

  describe 'combined YardOptions and Exclude configurations' do
    it 'both YardOptions and Exclude work together per-validator' do
      files = [
        File.join(fixtures_dir, 'private_methods.rb'),
        File.join(fixtures_dir, 'protected_methods.rb')
      ]

      config = Yard::Lint::Config.new(
        {
          'AllValidators' => {
            'YardOptions' => ['--private', '--protected'],
            'Exclude' => []
          },
          # This validator: no private visibility AND exclude protected_methods.rb
          'Documentation/UndocumentedObjects' => {
            'Enabled' => true,
            'YardOptions' => [],
            'Exclude' => ['**/protected_methods.rb']
          },
          # This validator: full visibility AND exclude private_methods.rb
          'Tags/Order' => {
            'Enabled' => true,
            'Exclude' => ['**/private_methods.rb']
          }
        }
      )

      runner = Yard::Lint::Runner.new(files, config)
      result = runner.run

      # UndocumentedObjects: public only AND only from private_methods.rb
      undoc_offenses = result.offenses.select { |o| o[:name] == 'UndocumentedObject' }
      # Should not see any protected_methods.rb offenses (file excluded)
      protected_undoc = undoc_offenses.select { |o| o[:location]&.include?('protected_methods.rb') }
      expect(protected_undoc).to be_empty
      # Should not see private methods (YardOptions: [])
      private_undoc = undoc_offenses.select { |o| o[:element]&.include?('private') }
      expect(private_undoc).to be_empty

      # Tags/Order: all visibility AND only from protected_methods.rb
      tag_order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
      # Should not see any private_methods.rb offenses (file excluded)
      private_order = tag_order_offenses.select { |o| o[:location]&.include?('private_methods.rb') }
      expect(private_order).to be_empty
      # Should see protected_methods.rb offenses
      protected_order = tag_order_offenses.select { |o| o[:location]&.include?('protected_methods.rb') }
      expect(protected_order).not_to be_empty
    end
  end

  describe 'validators with default in_process_visibility: :all' do
    # Some validators like Tags/Order and Tags/InvalidTypes have in_process_visibility: :all
    # by default. This tests that explicit empty YardOptions can override this.

    it 'Tags/Order defaults to :all but respects explicit empty YardOptions' do
      files = [File.join(fixtures_dir, 'mixed_visibility.rb')]

      # Without explicit YardOptions - inherits global empty, falls back to validator default (:all)
      config_without_override = Yard::Lint::Config.new(
        {
          'AllValidators' => {
            'YardOptions' => [],
            'Exclude' => []
          },
          'Tags/Order' => {
            'Enabled' => true
          }
        }
      )

      runner = Yard::Lint::Runner.new(files, config_without_override)
      result = runner.run

      # Should see all visibility levels (validator default is :all)
      tag_order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
      wrong_order_methods = tag_order_offenses.map { |o| o[:method_name] }
      expect(wrong_order_methods.any? { |m| m&.include?('private_wrong_order') }).to be true

      # With explicit empty YardOptions - should only see public
      config_with_override = Yard::Lint::Config.new(
        {
          'AllValidators' => {
            'YardOptions' => [],
            'Exclude' => []
          },
          'Tags/Order' => {
            'Enabled' => true,
            'YardOptions' => [] # Explicit override
          }
        }
      )

      runner2 = Yard::Lint::Runner.new(files, config_with_override)
      result2 = runner2.run

      # Should only see public visibility (explicit empty overrides validator default)
      tag_order_offenses2 = result2.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
      wrong_order_methods2 = tag_order_offenses2.map { |o| o[:method_name] }
      expect(wrong_order_methods2.any? { |m| m&.include?('public_wrong_order') }).to be true
      expect(wrong_order_methods2.none? { |m| m&.include?('private_wrong_order') }).to be true
    end
  end

  describe 'validators with default in_process_visibility: :public' do
    # Documentation validators like UndocumentedObjects have in_process_visibility: :public
    # This tests that --private YardOptions can expand their visibility

    it 'Documentation validators default to :public but can expand with --private' do
      files = [File.join(fixtures_dir, 'private_methods.rb')]

      # Without --private - should only see public methods
      config_public_only = Yard::Lint::Config.new(
        {
          'AllValidators' => {
            'YardOptions' => [],
            'Exclude' => []
          },
          'Documentation/UndocumentedMethodArguments' => {
            'Enabled' => true
          }
        }
      )

      runner = Yard::Lint::Runner.new(files, config_public_only)
      result = runner.run

      undoc_arg_offenses = result.offenses.select { |o| o[:name] == 'UndocumentedMethodArgument' }
      expect(undoc_arg_offenses.none? { |o| o[:method_name]&.include?('private') }).to be true

      # With --private - should see all methods
      config_with_private = Yard::Lint::Config.new(
        {
          'AllValidators' => {
            'YardOptions' => [],
            'Exclude' => []
          },
          'Documentation/UndocumentedMethodArguments' => {
            'Enabled' => true,
            'YardOptions' => ['--private']
          }
        }
      )

      runner2 = Yard::Lint::Runner.new(files, config_with_private)
      result2 = runner2.run

      undoc_arg_offenses2 = result2.offenses.select { |o| o[:name] == 'UndocumentedMethodArgument' }
      expect(undoc_arg_offenses2.any? { |o| o[:method_name]&.include?('undocumented_private') }).to be true
    end
  end

  describe 'three validators with three different visibility settings' do
    it 'all three respect their individual settings simultaneously' do
      files = [File.join(fixtures_dir, 'mixed_visibility.rb')]

      config = Yard::Lint::Config.new(
        {
          'AllValidators' => {
            'YardOptions' => ['--private'],
            'Exclude' => []
          },
          # Validator 1: Explicit empty - public only
          'Documentation/UndocumentedMethodArguments' => {
            'Enabled' => true,
            'YardOptions' => []
          },
          # Validator 2: Inherits --private - all visibility
          'Tags/Order' => {
            'Enabled' => true
          },
          # Validator 3: Explicit --protected - all visibility (both flags enable :all)
          'Tags/InvalidTypes' => {
            'Enabled' => true,
            'YardOptions' => ['--protected']
          }
        }
      )

      runner = Yard::Lint::Runner.new(files, config)
      result = runner.run

      # Validator 1: public only
      undoc_arg_offenses = result.offenses.select { |o| o[:name] == 'UndocumentedMethodArgument' }
      expect(undoc_arg_offenses.any? { |o| o[:method_name]&.include?('public_undocumented') }).to be true
      expect(undoc_arg_offenses.none? { |o| o[:method_name]&.include?('private_undocumented') }).to be true
      expect(undoc_arg_offenses.none? { |o| o[:method_name]&.include?('protected_undocumented') }).to be true

      # Validator 2: all visibility
      tag_order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
      expect(tag_order_offenses.any? { |o| o[:method_name]&.include?('public_wrong_order') }).to be true
      expect(tag_order_offenses.any? { |o| o[:method_name]&.include?('private_wrong_order') }).to be true
      expect(tag_order_offenses.any? { |o| o[:method_name]&.include?('protected_wrong_order') }).to be true
    end
  end

  describe 'edge case: validator config without YardOptions key' do
    it 'inherits from global when YardOptions key is absent' do
      files = [File.join(fixtures_dir, 'private_methods.rb')]

      config = Yard::Lint::Config.new(
        {
          'AllValidators' => {
            'YardOptions' => ['--private'],
            'Exclude' => []
          },
          # Only Enabled key, no YardOptions - should inherit from AllValidators
          'Tags/Order' => {
            'Enabled' => true
          }
        }
      )

      runner = Yard::Lint::Runner.new(files, config)
      result = runner.run

      # Should see private methods (inherited --private from AllValidators)
      tag_order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
      expect(tag_order_offenses.any? { |o| o[:method_name]&.include?('documented_private_wrong_order') }).to be true
    end
  end

  describe 'complex scenario: multiple files with mixed visibility' do
    it 'correctly applies per-validator YardOptions across multiple files' do
      files = [
        File.join(fixtures_dir, 'private_methods.rb'),
        File.join(fixtures_dir, 'protected_methods.rb'),
        File.join(fixtures_dir, 'mixed_visibility.rb')
      ]

      config = Yard::Lint::Config.new(
        {
          'AllValidators' => {
            'YardOptions' => ['--private', '--protected'],
            'Exclude' => []
          },
          # Public only for documentation checks
          'Documentation/UndocumentedMethodArguments' => {
            'Enabled' => true,
            'YardOptions' => []
          },
          # All visibility for tag checks
          'Tags/Order' => {
            'Enabled' => true
          }
        }
      )

      runner = Yard::Lint::Runner.new(files, config)
      result = runner.run

      # Documentation: only public methods from all three files
      undoc_arg_offenses = result.offenses.select { |o| o[:name] == 'UndocumentedMethodArgument' }
      undoc_methods = undoc_arg_offenses.map { |o| o[:method_name] }
      expect(undoc_methods.none? { |m| m&.include?('private') }).to be true
      expect(undoc_methods.none? { |m| m&.include?('protected') }).to be true

      # Tags/Order: should see wrong order from all visibility levels across all files
      tag_order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
      wrong_order_methods = tag_order_offenses.map { |o| o[:method_name] }

      # Should have offenses from all three files
      expect(tag_order_offenses.any? { |o| o[:location]&.include?('private_methods.rb') }).to be true
      expect(tag_order_offenses.any? { |o| o[:location]&.include?('protected_methods.rb') }).to be true
      expect(tag_order_offenses.any? { |o| o[:location]&.include?('mixed_visibility.rb') }).to be true

      # Should include private and protected methods
      expect(wrong_order_methods.any? { |m| m&.include?('private') }).to be true
      expect(wrong_order_methods.any? { |m| m&.include?('protected') }).to be true
    end
  end

  describe 'YardOptions array with multiple flags' do
    it 'correctly handles arrays with multiple YARD options' do
      files = [File.join(fixtures_dir, 'mixed_visibility.rb')]

      config = Yard::Lint::Config.new(
        {
          'AllValidators' => {
            'YardOptions' => [],
            'Exclude' => []
          },
          'Tags/Order' => {
            'Enabled' => true,
            # Multiple options in array
            'YardOptions' => ['--private', '--protected', '--no-cache']
          }
        }
      )

      runner = Yard::Lint::Runner.new(files, config)
      result = runner.run

      # Should see all visibility levels (--private flag present)
      tag_order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
      wrong_order_methods = tag_order_offenses.map { |o| o[:method_name] }
      expect(wrong_order_methods.any? { |m| m&.include?('private_wrong_order') }).to be true
      expect(wrong_order_methods.any? { |m| m&.include?('protected_wrong_order') }).to be true
    end
  end

  describe 'YardOptions with partial flag matches' do
    it 'correctly matches --private and --protected flags' do
      files = [File.join(fixtures_dir, 'mixed_visibility.rb')]

      # Test that --private-api or similar doesn't falsely match
      config = Yard::Lint::Config.new(
        {
          'AllValidators' => {
            'YardOptions' => [],
            'Exclude' => []
          },
          'Tags/Order' => {
            'Enabled' => true,
            'YardOptions' => ['--private'] # Exact match should work
          }
        }
      )

      runner = Yard::Lint::Runner.new(files, config)
      result = runner.run

      tag_order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
      expect(tag_order_offenses.any? { |o| o[:method_name]&.include?('private_wrong_order') }).to be true
    end
  end
end

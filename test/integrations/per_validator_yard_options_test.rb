# frozen_string_literal: true

require 'test_helper'

class PerValidatorYardoptionsConfigurationTest < Minitest::Test
  attr_reader :fixtures_dir

  def setup
    @fixtures_dir = File.expand_path('fixtures', __dir__)
  end

  def test_validator_specific_yardoptions_override_global_options_when_global_has_private_but_validator_ha
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
      assert_empty(private_undoc)

      # Tags/Order SHOULD see private methods and report wrong order
      tag_order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
      private_order = tag_order_offenses.select { |o| o[:method_name]&.include?('documented_private_wrong_order') }
      refute_empty(private_order)
  end

  def test_validator_specific_yardoptions_override_global_options_when_global_has_no_private_but_validator
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
      assert_empty(private_undoc)

      # Tags/Order SHOULD see private methods due to its own --private YardOption
      tag_order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
      private_order = tag_order_offenses.select { |o| o[:method_name]&.include?('documented_private_wrong_order') }
      refute_empty(private_order)
  end

  def test_different_validators_with_different_visibility_settings_allows_fine_grained_control_over_which_
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
    assert_equal(true, undoc_methods.any? { |m| m&.include?('public_undocumented') })
    # Should NOT see protected_undocumented or private_undocumented (public visibility only)
    assert_equal(true, undoc_methods.none? { |m| m&.include?('protected_undocumented') })
    assert_equal(true, undoc_methods.none? { |m| m&.include?('private_undocumented') })

    # Tags/Order should see ALL visibility levels (inherits --private --protected)
    tag_order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
    wrong_order_methods = tag_order_offenses.map { |o| o[:method_name] }

    # Should see wrong_order methods from all visibility levels
    assert_equal(true, wrong_order_methods.any? { |m| m&.include?('public_wrong_order') })
    assert_equal(true, wrong_order_methods.any? { |m| m&.include?('protected_wrong_order') })
    assert_equal(true, wrong_order_methods.any? { |m| m&.include?('private_wrong_order') })
  end

  def test_protected_visibility_configuration_treats_protected_as_including_all_non_public_visibility_leve
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

    assert_equal(true, wrong_order_methods.any? { |m| m&.include?('public_wrong_order') })
    assert_equal(true, wrong_order_methods.any? { |m| m&.include?('protected_wrong_order') })
    assert_equal(true, wrong_order_methods.any? { |m| m&.include?('private_wrong_order') })

    # UndocumentedMethodArguments should only see public (inherits empty global)
    undoc_arg_offenses = result.offenses.select { |o| o[:name] == 'UndocumentedMethodArgument' }
    undoc_methods = undoc_arg_offenses.map { |o| o[:method_name] }
    assert_equal(true, undoc_methods.any? { |m| m&.include?('public_undocumented') })
    assert_equal(true, undoc_methods.none? { |m| m&.include?('protected_undocumented') })
    assert_equal(true, undoc_methods.none? { |m| m&.include?('private_undocumented') })
  end

  def test_multiple_validators_each_with_different_yardoptions_each_validator_respects_its_own_yardoptions
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
    assert_equal(true, undoc_arg_methods.any? { |m| m&.include?('public_undocumented') })
    assert_equal(true, undoc_arg_methods.none? { |m| m&.include?('protected_undocumented') })
    assert_equal(true, undoc_arg_methods.none? { |m| m&.include?('private_undocumented') })

    # Validator B (Tags/Order): all visibility
    tag_order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
    wrong_order_methods = tag_order_offenses.map { |o| o[:method_name] }
    assert_equal(true, wrong_order_methods.any? { |m| m&.include?('public_wrong_order') })
    assert_equal(true, wrong_order_methods.any? { |m| m&.include?('protected_wrong_order') })
    assert_equal(true, wrong_order_methods.any? { |m| m&.include?('private_wrong_order') })
  end

  def test_yardoptions_with_tags_validators_with_invalidtypes_validator_respects_per_validator_yardoptions
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
      assert_equal(true, tag_order_offenses.any? { |o| o[:method_name]&.include?('private') })
  end

  def test_yardoptions_with_tags_validators_with_typesyntax_validator_respects_per_validator_yardoptions_f
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
      assert_empty(private_offenses)
  end

  def test_yardoptions_inheritance_and_fallback_behavior_validators_without_explicit_yardoptions_inherit_f
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
    refute_empty(private_order)
  end

  def test_yardoptions_inheritance_and_fallback_behavior_explicit_empty_yardoptions_overrides_global_non_e
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
    assert_empty(private_order)

    # Should still see public method issues
    public_order = tag_order_offenses.select { |o| o[:method_name]&.include?('public') }
    # private_methods.rb only has public_method which has correct docs
    assert_empty(public_order)
  end

  def test_regression_test_config_validator_yard_options_is_used_for_visibility_uses_validator_yard_option
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
    assert_empty(constant_offenses)

    # The colorize private method SHOULD trigger InvalidTagOrder
    # because Tags/Order inherits --private from AllValidators
    tag_order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
    colorize_offense = tag_order_offenses.find { |o| o[:method_name] == 'colorize' }
    refute_nil(colorize_offense)
  end

  def test_combined_yardoptions_and_exclude_configurations_both_yardoptions_and_exclude_work_together_per_
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
    assert_empty(protected_undoc)
    # Should not see private methods (YardOptions: [])
    private_undoc = undoc_offenses.select { |o| o[:element]&.include?('private') }
    assert_empty(private_undoc)

    # Tags/Order: all visibility AND only from protected_methods.rb
    tag_order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
    # Should not see any private_methods.rb offenses (file excluded)
    private_order = tag_order_offenses.select { |o| o[:location]&.include?('private_methods.rb') }
    assert_empty(private_order)
    # Should see protected_methods.rb offenses
    protected_order = tag_order_offenses.select { |o| o[:location]&.include?('protected_methods.rb') }
    refute_empty(protected_order)
  end
  # Some validators like Tags/Order and Tags/InvalidTypes have in_process_visibility: :all
  # by default. This tests that explicit empty YardOptions can override this.

  def test_validators_with_default_in_process_visibility_all_tags_order_defaults_to_all_but_respects_expli
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
    assert_equal(true, wrong_order_methods.any? { |m| m&.include?('private_wrong_order') })

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
    assert_equal(true, wrong_order_methods2.any? { |m| m&.include?('public_wrong_order') })
    assert_equal(true, wrong_order_methods2.none? { |m| m&.include?('private_wrong_order') })
  end
  # Documentation validators like UndocumentedObjects have in_process_visibility: :public
  # This tests that --private YardOptions can expand their visibility

  def test_validators_with_default_in_process_visibility_public_documentation_validators_default_to_public
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
    assert_equal(true, undoc_arg_offenses.none? { |o| o[:method_name]&.include?('private') })

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
    assert_equal(true, undoc_arg_offenses2.any? { |o| o[:method_name]&.include?('undocumented_private') })
  end

  def test_three_validators_with_three_different_visibility_settings_all_three_respect_their_individual_se
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
    assert_equal(true, undoc_arg_offenses.any? { |o| o[:method_name]&.include?('public_undocumented') })
    assert_equal(true, undoc_arg_offenses.none? { |o| o[:method_name]&.include?('private_undocumented') })
    assert_equal(true, undoc_arg_offenses.none? { |o| o[:method_name]&.include?('protected_undocumented') })

    # Validator 2: all visibility
    tag_order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
    assert_equal(true, tag_order_offenses.any? { |o| o[:method_name]&.include?('public_wrong_order') })
    assert_equal(true, tag_order_offenses.any? { |o| o[:method_name]&.include?('private_wrong_order') })
    assert_equal(true, tag_order_offenses.any? { |o| o[:method_name]&.include?('protected_wrong_order') })
  end

  def test_edge_case_validator_config_without_yardoptions_key_inherits_from_global_when_yardoptions_key_is
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
    assert_equal(true, tag_order_offenses.any? { |o| o[:method_name]&.include?('documented_private_wrong_order') })
  end

  def test_complex_scenario_multiple_files_with_mixed_visibility_correctly_applies_per_validator_yardoptio
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
    assert_equal(true, undoc_methods.none? { |m| m&.include?('private') })
    assert_equal(true, undoc_methods.none? { |m| m&.include?('protected') })

    # Tags/Order: should see wrong order from all visibility levels across all files
    tag_order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
    wrong_order_methods = tag_order_offenses.map { |o| o[:method_name] }

    # Should have offenses from all three files
    assert_equal(true, tag_order_offenses.any? { |o| o[:location]&.include?('private_methods.rb') })
    assert_equal(true, tag_order_offenses.any? { |o| o[:location]&.include?('protected_methods.rb') })
    assert_equal(true, tag_order_offenses.any? { |o| o[:location]&.include?('mixed_visibility.rb') })

    # Should include private and protected methods
    assert_equal(true, wrong_order_methods.any? { |m| m&.include?('private') })
    assert_equal(true, wrong_order_methods.any? { |m| m&.include?('protected') })
  end

  def test_yardoptions_array_with_multiple_flags_correctly_handles_arrays_with_multiple_yard_options
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
    assert_equal(true, wrong_order_methods.any? { |m| m&.include?('private_wrong_order') })
    assert_equal(true, wrong_order_methods.any? { |m| m&.include?('protected_wrong_order') })
  end

  def test_yardoptions_with_partial_flag_matches_correctly_matches_private_and_protected_flags
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
    assert_equal(true, tag_order_offenses.any? { |o| o[:method_name]&.include?('private_wrong_order') })
  end
end


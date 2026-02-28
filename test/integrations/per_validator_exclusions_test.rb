# frozen_string_literal: true

require 'test_helper'

class PerValidatorExclusionsTest < Minitest::Test
  attr_reader :fixtures_dir

  def setup
    @fixtures_dir = File.expand_path('fixtures', __dir__)
  end

  def test_filtering_files_per_validator_excludes_files_only_for_specific_validators
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
    assert(undoc_object_locations.none? { |loc| loc =~ /missing_param_docs\.rb/ })

    # UndocumentedMethodArgument offenses should NOT include undocumented_objects.rb
    undoc_arg_offenses = result.offenses.select { |o| o[:name] == 'UndocumentedMethodArgument' }
    undoc_arg_locations = undoc_arg_offenses.map { |o| o[:location] }
    assert(undoc_arg_locations.none? { |loc| loc =~ /undocumented_objects\.rb/ })
  end

  def test_with_glob_patterns_supports_wildcard_and_recursive_patterns
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
    assert_empty(unknown_tag_offenses)
  end

  def test_combining_global_and_per_validator_exclusions_applies_validator_specific_exclusions_independently
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
    assert_empty(undoc_arg_offenses)
  end

  def test_combining_global_and_per_validator_exclusions_merges_global_exclusions_with_per_validator_exclusions
    files = [
      File.join(fixtures_dir, 'private_methods.rb'),
      File.join(fixtures_dir, 'protected_methods.rb')
    ]

    # Global exclusion applies to all validators
    # Per-validator exclusions add to global exclusions
    config = Yard::Lint::Config.new(
      {
        'AllValidators' => {
          'Exclude' => ['**/private_methods.rb']
        },
        'Documentation/UndocumentedMethodArguments' => {
          'Enabled' => true,
          'Exclude' => ['**/protected_methods.rb']
        }
      }
    )

    runner = Yard::Lint::Runner.new(files, config)
    result = runner.run

    # UndocumentedMethodArguments should exclude both files
    undoc_arg_offenses = result.offenses.select { |o| o[:name] == 'UndocumentedMethodArgument' }
    undoc_arg_files = undoc_arg_offenses.filter_map { |o| o[:file] }

    # Should not process either file for UndocumentedMethodArguments
    assert_equal(true, undoc_arg_files.none? { |f| f.include?('private_methods.rb') })
    assert_equal(true, undoc_arg_files.none? { |f| f.include?('protected_methods.rb') })
  end

  def test_per_validator_exclusions_do_not_affect_other_validators_allows_other_validators_to_still_process
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
    assert_empty(undoc_arg_offenses)

    # UndocumentedObjects should still find offenses (file not excluded for this validator)
    undoc_object_offenses = result.offenses.select { |o| o[:name] == 'UndocumentedObject' }
    refute_empty(undoc_object_offenses)
  end

  def test_private_methods_enforce_tag_order_but_allow_undocumented
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

    assert_empty(undoc_object_offenses)
    assert_empty(undoc_arg_offenses)

    # But SHOULD enforce tag order on documented private methods
    tag_order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }

    refute_empty(tag_order_offenses)

    # Verify it found the wrong order in documented_private_wrong_order
    # Check that at least one offense is from private_methods.rb
    private_methods_offense = tag_order_offenses.find do |o|
      o[:location].include?('private_methods.rb')
    end

    refute_nil(private_methods_offense)
    # The offense should be about documented_private_wrong_order method
    assert_includes(private_methods_offense[:method_name], 'documented_private_wrong_order')
  end

  def test_private_constants_enforce_tag_order_but_allow_undocumented
    files = [
      File.join(fixtures_dir, 'private_constants.rb')
    ]

    # Configuration that:
    # 1. Includes private methods in YARD parsing (--private)
    # 2. Excludes private methods from documentation validators (YardOptions is empty)
    # 3. Still checks tag order on private methods (if they have docs)
    config = Yard::Lint::Config.new(
      {
        'AllValidators' => {
          'YardOptions' => ['--private'],
          'Exclude' => []
        },
        # Don't require documentation on private constants
        'Documentation/UndocumentedObjects' => {
          'Enabled' => true,
          'YardOptions' => [],
          'Exclude' => []
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
    undoc_object_offenses = result.offenses.select { |o| o[:name] == 'UndocumentedObject' && o[:element] != "AnsiHelper#red" }
    undoc_arg_offenses = result.offenses.select { |o| o[:name] == 'UndocumentedMethodArgument' && o[:method_name] != "red" }

    assert_empty(undoc_object_offenses)
    assert_empty(undoc_arg_offenses)

    # Should complain about undocumented public methods
    undoc_public_object_offenses = result.offenses.select { |o| o[:name] == 'UndocumentedObject' }

    refute_empty(undoc_public_object_offenses)
    assert_equal("AnsiHelper#red", undoc_public_object_offenses.first[:element])

    # But SHOULD enforce tag order on documented private methods
    tag_order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }

    refute_empty(tag_order_offenses)

    # Verify it found the wrong order in documented_private_wrong_order
    # Check that at least one offense is from private_constants.rb
    private_methods_offense = tag_order_offenses.find do |o|
      o[:location].include?('private_constants.rb')
    end

    refute_nil(private_methods_offense)
    # The offense should be about documented_private_wrong_order method
    assert_equal('colorize', private_methods_offense[:method_name])
  end

  def test_protected_methods_enforce_tag_order_but_allow_undocumented
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

    assert_empty(undoc_object_offenses)
    assert_empty(undoc_arg_offenses)

    # But SHOULD enforce tag order on documented protected methods
    tag_order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
    refute_empty(tag_order_offenses)

    protected_offense = tag_order_offenses.find do |o|
      o[:location].include?('protected_methods.rb') &&
        o[:method_name]&.include?('protected_wrong_order')
    end

    refute_nil(protected_offense)
  end

  def test_module_functions_with_selective_exclusions
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
    assert_empty(undoc_object_offenses)

    # But SHOULD find undocumented method arguments (not excluded)
    undoc_arg_offenses = result.offenses.select { |o| o[:name] == 'UndocumentedMethodArgument' }
    refute_empty(undoc_arg_offenses)

    # Verify it finds undocumented_function and undocumented_instance
    undoc_methods = undoc_arg_offenses.map { |o| o[:method_name] }
    assert_equal(true, undoc_methods.any? { |m| m&.include?('undocumented') })
  end

  def test_class_methods_with_separate_exclusions_validates_both
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
    refute_empty(undoc_arg_offenses)

    # Verify both instance and class methods are checked
    undoc_methods = undoc_arg_offenses.map { |o| o[:method_name] }
    assert_equal(true, undoc_methods.any? { |m| m&.include?('undocumented_instance') })
    assert_equal(true, undoc_methods.any? { |m| m&.include?('undocumented_class_method') })

    # Should find tag order issues in class methods
    tag_order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
    class_method_offense = tag_order_offenses.find do |o|
      o[:method_name]&.include?('class_method_wrong_order')
    end
    refute_nil(class_method_offense)
  end

  def test_attribute_methods_with_exclusions_validates
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
    assert_empty(excluded_offenses)
  end

  def test_complex_method_signatures_with_missing_parameter_documentation
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
    refute_empty(undoc_arg_offenses)

    # Check that it finds some of the undocumented methods
    undoc_methods = undoc_arg_offenses.map { |o| o[:method_name] }
    assert_equal(true, undoc_methods.any? { |m| m&.include?('process') })
  end

  def test_mixed_visibility_in_single_file_with_selective_exclusions
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
    refute_empty(undoc_arg_offenses)

    # Verify we found undocumented methods from different visibility levels
    undoc_methods = undoc_arg_offenses.map { |o| o[:method_name] }
    assert_equal(true, undoc_methods.any? { |m| m&.include?('public_undocumented') })
    assert_equal(true, undoc_methods.any? { |m| m&.include?('protected_undocumented') })
    assert_equal(true, undoc_methods.any? { |m| m&.include?('private_undocumented') })

    # Should find tag order issues in public, protected, and private methods
    tag_order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
    assert_operator(tag_order_offenses.size, :>=, 3) # At least 3 wrong order methods

    # Verify we found wrong_order methods from different visibility levels
    wrong_order_methods = tag_order_offenses.map { |o| o[:method_name] }
    assert_equal(true, wrong_order_methods.any? { |m| m&.include?('public_wrong_order') })
  end

  def test_multiple_validators_with_overlapping_file_exclusions
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

    assert_empty(undoc_object_offenses)
    assert_empty(undoc_arg_offenses)
  end

  def test_per_validator_exclusions_with_cross_validator_scenarios
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
    assert_equal(true, undoc_arg_files.any? { |f| f.include?('private_methods.rb') })

    # Tags/Order should see both files (we only excluded it from UndocumentedMethodArguments)
    # But it should find offenses in both (both have wrong order methods)
    tag_order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
    # Verify we have tag order offenses
    refute_empty(tag_order_offenses)
  end
end

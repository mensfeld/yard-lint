# frozen_string_literal: true

require 'test_helper'

class BlankLineBeforeDefinitionIntegrationTest < Minitest::Test
  attr_reader :config, :fixture_path

  def setup
    @fixture_path = File.expand_path('../fixtures/blank_line_before_definition.rb', __dir__)
    @config = test_config do |c|
      c.send(:set_validator_config, 'Documentation/BlankLineBeforeDefinition', 'Enabled', true)
    end
  end

  def test_detecting_blank_lines_before_definitions_finds_single_blank_line_violations_public_methods_only
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    single_offenses = result.offenses.select do |o|
      o[:name] == 'BlankLineBeforeDefinition' &&
        o[:message].include?('Blank line between documentation and definition')
    end

    # Should find PUBLIC only: single_blank_line, method_with_single_blank,
    # MySingleBlankClass, MySingleBlankModule
    # (protected_single_blank and private_single_blank NOT included by default)
    assert_equal(4, single_offenses.size)
  end

  def test_detecting_blank_lines_before_definitions_finds_orphaned_documentation_violations_public_methods
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    orphaned_offenses = result.offenses.select do |o|
      o[:name] == 'BlankLineBeforeDefinition' &&
        o[:message].include?('orphaned')
    end

    # Should find PUBLIC only: two_blank_lines, three_blank_lines,
    # MyOrphanedClass, MyOrphanedModule
    # (protected_orphaned_docs and private_orphaned_docs NOT included by default)
    assert_equal(4, orphaned_offenses.size)
  end

  def test_detecting_blank_lines_before_definitions_does_not_flag_methods_with_no_blank_lines
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    valid_offenses = result.offenses.select do |o|
      o[:name] == 'BlankLineBeforeDefinition' &&
        (o[:message].include?('valid_no_blank_lines') ||
         o[:message].include?('another_valid_method') ||
         o[:message].include?('MyValidClass') ||
         o[:message].include?('MyValidModule'))
    end

    assert_empty(valid_offenses)
  end

  def test_detecting_blank_lines_before_definitions_provides_helpful_error_messages_for_single_blank_line
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find do |o|
      o[:name] == 'BlankLineBeforeDefinition' &&
        o[:message].include?('single_blank_line')
    end

    refute_nil(offense)
    assert_includes(offense[:message], 'Blank line between documentation and definition')
  end

  def test_detecting_blank_lines_before_definitions_provides_helpful_error_messages_for_orphaned_docs
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find do |o|
      o[:name] == 'BlankLineBeforeDefinition' &&
        o[:message].include?('two_blank_lines')
    end

    refute_nil(offense)
    assert_includes(offense[:message], 'orphaned')
    assert_includes(offense[:message], '2 blank lines')
  end

  def test_detecting_blank_lines_before_definitions_includes_blank_line_count_for_orphaned_docs_with_3_lines
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find do |o|
      o[:name] == 'BlankLineBeforeDefinition' &&
        o[:message].include?('three_blank_lines')
    end

    refute_nil(offense)
    assert_includes(offense[:message], '3 blank lines')
  end

  def test_configuration_options_when_only_checking_single_blank_lines_only_finds_single_blank_line_violations
    single_only_config = test_config do |c|
      c.send(:set_validator_config, 'Documentation/BlankLineBeforeDefinition', 'Enabled', true)
      c.send(
        :set_validator_config,
        'Documentation/BlankLineBeforeDefinition',
        'EnabledPatterns',
        { 'SingleBlankLine' => true, 'OrphanedDocs' => false }
      )
    end

    result = Yard::Lint.run(path: fixture_path, config: single_only_config, progress: false)

    offenses = result.offenses.select { |o| o[:name] == 'BlankLineBeforeDefinition' }

    offenses.each do |offense|
      refute_includes(offense[:message], 'orphaned')
    end
  end

  def test_configuration_options_when_only_checking_orphaned_docs_only_finds_orphaned_documentation_violations
    orphaned_only_config = test_config do |c|
      c.send(:set_validator_config, 'Documentation/BlankLineBeforeDefinition', 'Enabled', true)
      c.send(
        :set_validator_config,
        'Documentation/BlankLineBeforeDefinition',
        'EnabledPatterns',
        { 'SingleBlankLine' => false, 'OrphanedDocs' => true }
      )
    end

    result = Yard::Lint.run(path: fixture_path, config: orphaned_only_config, progress: false)

    offenses = result.offenses.select { |o| o[:name] == 'BlankLineBeforeDefinition' }

    offenses.each do |offense|
      assert_includes(offense[:message], 'orphaned')
    end
  end

  def test_configuration_options_when_configuring_custom_severities_uses_configured_severity_for_single_blank_line
    custom_severity_config = test_config do |c|
      c.send(:set_validator_config, 'Documentation/BlankLineBeforeDefinition', 'Enabled', true)
      c.send(:set_validator_config, 'Documentation/BlankLineBeforeDefinition', 'Severity', 'warning')
      c.send(:set_validator_config, 'Documentation/BlankLineBeforeDefinition', 'OrphanedSeverity', 'error')
    end

    result = Yard::Lint.run(path: fixture_path, config: custom_severity_config, progress: false)

    single_offense = result.offenses.find do |o|
      o[:name] == 'BlankLineBeforeDefinition' &&
        !o[:message].include?('orphaned')
    end

    assert_equal('warning', single_offense[:severity])
  end

  def test_configuration_options_when_configuring_custom_severities_uses_orphanedseverity_for_orphaned_docs
    custom_severity_config = test_config do |c|
      c.send(:set_validator_config, 'Documentation/BlankLineBeforeDefinition', 'Enabled', true)
      c.send(:set_validator_config, 'Documentation/BlankLineBeforeDefinition', 'Severity', 'warning')
      c.send(:set_validator_config, 'Documentation/BlankLineBeforeDefinition', 'OrphanedSeverity', 'error')
    end

    result = Yard::Lint.run(path: fixture_path, config: custom_severity_config, progress: false)

    orphaned_offense = result.offenses.find do |o|
      o[:name] == 'BlankLineBeforeDefinition' &&
        o[:message].include?('orphaned')
    end

    assert_equal('error', orphaned_offense[:severity])
  end

  def test_when_disabled_does_not_run_validation
    disabled_config = test_config do |c|
      c.send(:set_validator_config, 'Documentation/BlankLineBeforeDefinition', 'Enabled', false)
    end

    result = Yard::Lint.run(path: fixture_path, config: disabled_config, progress: false)

    blank_line_offenses = result.offenses.select { |o| o[:name] == 'BlankLineBeforeDefinition' }
    assert_empty(blank_line_offenses)
  end

  def test_valid_documentation_is_not_flagged_does_not_flag_properly_formatted_docs
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    valid_offenses = result.offenses.select do |o|
      o[:name] == 'BlankLineBeforeDefinition' &&
        (o[:message].include?('valid_no_blank_lines') ||
         o[:message].include?('another_valid_method'))
    end

    assert_empty(valid_offenses)
  end

  def test_visibility_configuration_when_checking_private_methods_finds_violations
    private_config = test_config do |c|
      c.send(:set_validator_config, 'Documentation/BlankLineBeforeDefinition', 'Enabled', true)
      c.send(
        :set_validator_config,
        'Documentation/BlankLineBeforeDefinition',
        'YardOptions',
        ['--private']
      )
    end

    result = Yard::Lint.run(path: fixture_path, config: private_config, progress: false)

    offenses = result.offenses.select { |o| o[:name] == 'BlankLineBeforeDefinition' }
    offense_methods = offenses.map { |o| o[:object_name] }

    # Should find private methods with blank line issues
    assert_equal(true, offense_methods.any? { |m| m&.include?('private_single_blank') })
    assert_equal(true, offense_methods.any? { |m| m&.include?('private_orphaned_docs') })
  end

  def test_visibility_configuration_when_checking_private_methods_still_finds_public_violations
    private_config = test_config do |c|
      c.send(:set_validator_config, 'Documentation/BlankLineBeforeDefinition', 'Enabled', true)
      c.send(
        :set_validator_config,
        'Documentation/BlankLineBeforeDefinition',
        'YardOptions',
        ['--private']
      )
    end

    result = Yard::Lint.run(path: fixture_path, config: private_config, progress: false)

    offenses = result.offenses.select { |o| o[:name] == 'BlankLineBeforeDefinition' }
    offense_methods = offenses.map { |o| o[:object_name] }

    assert_equal(true, offense_methods.any? { |m| m&.include?('single_blank_line') })
  end

  def test_visibility_configuration_when_checking_protected_methods_finds_violations
    protected_config = test_config do |c|
      c.send(:set_validator_config, 'Documentation/BlankLineBeforeDefinition', 'Enabled', true)
      c.send(
        :set_validator_config,
        'Documentation/BlankLineBeforeDefinition',
        'YardOptions',
        ['--protected']
      )
    end

    result = Yard::Lint.run(path: fixture_path, config: protected_config, progress: false)

    offenses = result.offenses.select { |o| o[:name] == 'BlankLineBeforeDefinition' }
    offense_methods = offenses.map { |o| o[:object_name] }

    # Should find protected methods with blank line issues
    assert_equal(true, offense_methods.any? { |m| m&.include?('protected_single_blank') })
    assert_equal(true, offense_methods.any? { |m| m&.include?('protected_orphaned_docs') })
  end

  def test_visibility_configuration_when_checking_all_visibility_levels_finds_violations
    all_visibility_config = test_config do |c|
      c.send(:set_validator_config, 'Documentation/BlankLineBeforeDefinition', 'Enabled', true)
      c.send(
        :set_validator_config,
        'Documentation/BlankLineBeforeDefinition',
        'YardOptions',
        ['--private', '--protected']
      )
    end

    result = Yard::Lint.run(path: fixture_path, config: all_visibility_config, progress: false)

    offenses = result.offenses.select { |o| o[:name] == 'BlankLineBeforeDefinition' }
    offense_methods = offenses.map { |o| o[:object_name] }

    # Should find public, protected, AND private methods
    assert_equal(true, offense_methods.any? { |m| m&.include?('single_blank_line') })
    assert_equal(true, offense_methods.any? { |m| m&.include?('protected_single_blank') })
    assert_equal(true, offense_methods.any? { |m| m&.include?('private_single_blank') })
    assert_equal(true, offense_methods.any? { |m| m&.include?('protected_orphaned_docs') })
    assert_equal(true, offense_methods.any? { |m| m&.include?('private_orphaned_docs') })
  end

  def test_visibility_configuration_all_visibility_includes_more_violations_than_public_only
    all_visibility_config = test_config do |c|
      c.send(:set_validator_config, 'Documentation/BlankLineBeforeDefinition', 'Enabled', true)
      c.send(
        :set_validator_config,
        'Documentation/BlankLineBeforeDefinition',
        'YardOptions',
        ['--private', '--protected']
      )
    end

    public_result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
    all_result = Yard::Lint.run(path: fixture_path, config: all_visibility_config, progress: false)

    public_offenses = public_result.offenses.select { |o| o[:name] == 'BlankLineBeforeDefinition' }
    all_offenses = all_result.offenses.select { |o| o[:name] == 'BlankLineBeforeDefinition' }

    # All visibility should have more offenses than public only
    assert_operator(all_offenses.size, :>, public_offenses.size)
  end

  def test_visibility_configuration_global_yardoptions_overridden_by_validator
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
    assert_equal(true, offense_methods.none? { |m| m&.include?('private_single_blank') })
    assert_equal(true, offense_methods.none? { |m| m&.include?('private_orphaned_docs') })
  end

  def test_visibility_configuration_validator_inherits_global_private_yardoptions
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
    assert_equal(true, offense_methods.any? { |m| m&.include?('private_single_blank') })
    assert_equal(true, offense_methods.any? { |m| m&.include?('private_orphaned_docs') })
  end

  def test_does_not_flag_valid_private_methods_with_no_blank_lines
    all_visibility_config = test_config do |c|
      c.send(:set_validator_config, 'Documentation/BlankLineBeforeDefinition', 'Enabled', true)
      c.send(:set_validator_config, 'Documentation/BlankLineBeforeDefinition', 'YardOptions',
             ['--private', '--protected'])
    end

    result = Yard::Lint.run(path: fixture_path, config: all_visibility_config, progress: false)

    valid_offenses = result.offenses.select do |o|
      o[:name] == 'BlankLineBeforeDefinition' &&
        o[:object_name]&.include?('private_valid_method')
    end

    assert_empty(valid_offenses)
  end

  def test_does_not_flag_valid_protected_methods_with_no_blank_lines
    all_visibility_config = test_config do |c|
      c.send(:set_validator_config, 'Documentation/BlankLineBeforeDefinition', 'Enabled', true)
      c.send(:set_validator_config, 'Documentation/BlankLineBeforeDefinition', 'YardOptions',
             ['--private', '--protected'])
    end

    result = Yard::Lint.run(path: fixture_path, config: all_visibility_config, progress: false)

    valid_offenses = result.offenses.select do |o|
      o[:name] == 'BlankLineBeforeDefinition' &&
        o[:object_name]&.include?('protected_valid_method')
    end

    assert_empty(valid_offenses)
  end
end

# frozen_string_literal: true

require 'test_helper'


describe 'Blank Line Before Definition' do
  attr_reader :fixture_path, :config


  before do
    @fixture_path = File.expand_path('../fixtures/blank_line_before_definition.rb', __dir__)
    @config = test_config do |c|
      c.set_validator_config('Documentation/BlankLineBeforeDefinition', 'Enabled', true)
    end
  end

  it 'detecting blank lines before definitions finds single blank line violations public methods only' do
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

  it 'detecting blank lines before definitions finds orphaned documentation violations public methods' do
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

  it 'detecting blank lines before definitions does not flag methods with no blank lines' do
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

  it 'detecting blank lines before definitions provides helpful error messages for single blank line' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find do |o|
      o[:name] == 'BlankLineBeforeDefinition' &&
        o[:message].include?('single_blank_line')
    end

    refute_nil(offense)
    assert_includes(offense[:message], 'Blank line between documentation and definition')
  end

  it 'detecting blank lines before definitions provides helpful error messages for orphaned docs' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find do |o|
      o[:name] == 'BlankLineBeforeDefinition' &&
        o[:message].include?('two_blank_lines')
    end

    refute_nil(offense)
    assert_includes(offense[:message], 'orphaned')
    assert_includes(offense[:message], '2 blank lines')
  end

  it 'detecting blank lines before definitions includes blank line count for orphaned docs with 3 lines' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find do |o|
      o[:name] == 'BlankLineBeforeDefinition' &&
        o[:message].include?('three_blank_lines')
    end

    refute_nil(offense)
    assert_includes(offense[:message], '3 blank lines')
  end

  it 'configuration options when only checking single blank lines only finds single blank line violations' do
    single_only_config = test_config do |c|
      c.set_validator_config('Documentation/BlankLineBeforeDefinition', 'Enabled', true)
      c.set_validator_config('Documentation/BlankLineBeforeDefinition',
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

  it 'configuration options when only checking orphaned docs only finds orphaned documentation violations' do
    orphaned_only_config = test_config do |c|
      c.set_validator_config('Documentation/BlankLineBeforeDefinition', 'Enabled', true)
      c.set_validator_config('Documentation/BlankLineBeforeDefinition',
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

  it 'configuration options when configuring custom severities uses configured severity for single blank line' do
    custom_severity_config = test_config do |c|
      c.set_validator_config('Documentation/BlankLineBeforeDefinition', 'Enabled', true)
      c.set_validator_config('Documentation/BlankLineBeforeDefinition', 'Severity', 'warning')
      c.set_validator_config('Documentation/BlankLineBeforeDefinition', 'OrphanedSeverity', 'error')
    end

    result = Yard::Lint.run(path: fixture_path, config: custom_severity_config, progress: false)

    single_offense = result.offenses.find do |o|
      o[:name] == 'BlankLineBeforeDefinition' &&
        !o[:message].include?('orphaned')
    end

    assert_equal('warning', single_offense[:severity])
  end

  it 'configuration options when configuring custom severities uses orphanedseverity for orphaned docs' do
    custom_severity_config = test_config do |c|
      c.set_validator_config('Documentation/BlankLineBeforeDefinition', 'Enabled', true)
      c.set_validator_config('Documentation/BlankLineBeforeDefinition', 'Severity', 'warning')
      c.set_validator_config('Documentation/BlankLineBeforeDefinition', 'OrphanedSeverity', 'error')
    end

    result = Yard::Lint.run(path: fixture_path, config: custom_severity_config, progress: false)

    orphaned_offense = result.offenses.find do |o|
      o[:name] == 'BlankLineBeforeDefinition' &&
        o[:message].include?('orphaned')
    end

    assert_equal('error', orphaned_offense[:severity])
  end

  it 'when disabled does not run validation' do
    disabled_config = test_config do |c|
      c.set_validator_config('Documentation/BlankLineBeforeDefinition', 'Enabled', false)
    end

    result = Yard::Lint.run(path: fixture_path, config: disabled_config, progress: false)

    blank_line_offenses = result.offenses.select { |o| o[:name] == 'BlankLineBeforeDefinition' }
    assert_empty(blank_line_offenses)
  end

  it 'valid documentation is not flagged does not flag properly formatted docs' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    valid_offenses = result.offenses.select do |o|
      o[:name] == 'BlankLineBeforeDefinition' &&
        (o[:message].include?('valid_no_blank_lines') ||
         o[:message].include?('another_valid_method'))
    end

    assert_empty(valid_offenses)
  end

  it 'visibility configuration when checking private methods finds violations' do
    private_config = test_config do |c|
      c.set_validator_config('Documentation/BlankLineBeforeDefinition', 'Enabled', true)
      c.set_validator_config('Documentation/BlankLineBeforeDefinition',
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

  it 'visibility configuration when checking private methods still finds public violations' do
    private_config = test_config do |c|
      c.set_validator_config('Documentation/BlankLineBeforeDefinition', 'Enabled', true)
      c.set_validator_config('Documentation/BlankLineBeforeDefinition',
        'YardOptions',
        ['--private']
      )
    end

    result = Yard::Lint.run(path: fixture_path, config: private_config, progress: false)

    offenses = result.offenses.select { |o| o[:name] == 'BlankLineBeforeDefinition' }
    offense_methods = offenses.map { |o| o[:object_name] }

    assert_equal(true, offense_methods.any? { |m| m&.include?('single_blank_line') })
  end

  it 'visibility configuration when checking protected methods finds violations' do
    protected_config = test_config do |c|
      c.set_validator_config('Documentation/BlankLineBeforeDefinition', 'Enabled', true)
      c.set_validator_config('Documentation/BlankLineBeforeDefinition',
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

  it 'visibility configuration when checking all visibility levels finds violations' do
    all_visibility_config = test_config do |c|
      c.set_validator_config('Documentation/BlankLineBeforeDefinition', 'Enabled', true)
      c.set_validator_config('Documentation/BlankLineBeforeDefinition',
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

  it 'visibility configuration all visibility includes more violations than public only' do
    all_visibility_config = test_config do |c|
      c.set_validator_config('Documentation/BlankLineBeforeDefinition', 'Enabled', true)
      c.set_validator_config('Documentation/BlankLineBeforeDefinition',
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

  it 'visibility configuration global yardoptions overridden by validator' do
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

  it 'visibility configuration validator inherits global private yardoptions' do
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

  it 'does not flag valid private methods with no blank lines' do
    all_visibility_config = test_config do |c|
      c.set_validator_config('Documentation/BlankLineBeforeDefinition', 'Enabled', true)
      c.set_validator_config('Documentation/BlankLineBeforeDefinition', 'YardOptions',
             ['--private', '--protected'])
    end

    result = Yard::Lint.run(path: fixture_path, config: all_visibility_config, progress: false)

    valid_offenses = result.offenses.select do |o|
      o[:name] == 'BlankLineBeforeDefinition' &&
        o[:object_name]&.include?('private_valid_method')
    end

    assert_empty(valid_offenses)
  end

  it 'does not flag valid protected methods with no blank lines' do
    all_visibility_config = test_config do |c|
      c.set_validator_config('Documentation/BlankLineBeforeDefinition', 'Enabled', true)
      c.set_validator_config('Documentation/BlankLineBeforeDefinition', 'YardOptions',
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

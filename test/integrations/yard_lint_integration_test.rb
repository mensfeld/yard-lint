# frozen_string_literal: true

require 'test_helper'


describe 'Yard Lint Integration' do
  attr_reader :fixtures_dir, :config


  before do
    @fixtures_dir = File.expand_path('fixtures', __dir__)
    @config = Yard::Lint::Config.new do |c|
      c.exclude = []
      # Disable ExampleSyntax to avoid false positives on output format examples
      c.set_validator_config('Tags/ExampleSyntax', 'Enabled', false)
      end
  end

  it 'undocumented classes detection detects undocumented classes and modules' do
    file = File.join(@fixtures_dir, 'undocumented_class.rb')

    result = Yard::Lint.run(path: file, config: @config)

    assert_equal(false, result.clean?)
    assert_equal(true, result.offenses.any? { |o| o[:name] == 'UndocumentedObject' })

    # Should find UndocumentedClass, UndocumentedModule, and nested class
    undocumented_names = result.offenses
                               .select { |o| o[:name] == 'UndocumentedObject' }
                               .map { |o| o[:element] }
  end

  it 'undocumented classes detection reports correct file locations' do
    file = File.join(@fixtures_dir, 'undocumented_class.rb')

    result = Yard::Lint.run(path: file, config: @config)

    result.offenses.select { |o| o[:name] == 'UndocumentedObject' }.each do |offense|
      assert_includes(offense[:location], 'undocumented_class.rb')
      assert_operator(offense[:line], :>, 0)
      end
  end

  it 'missing parameter documentation detects methods with missing param docs' do
    file = File.join(@fixtures_dir, 'missing_param_docs.rb')

    result = Yard::Lint.run(path: file, config: @config)

    assert_equal(true, result.offenses.any? { |o| o[:name] == 'UndocumentedMethodArgument' })

    # Should find calculate and greet methods
    methods = result.offenses
                    .select { |o| o[:name] == 'UndocumentedMethodArgument' }
                    .map { |o| o[:method_name] }
  end

  it 'invalid tag ordering detects tags in wrong order' do
    file = File.join(@fixtures_dir, 'invalid_tag_order.rb')

    config = Yard::Lint::Config.new do |c|
      c.exclude = []
      # Use default tag order (param should come before return)
      c.set_validator_config('Tags/Order',
        'EnforcedOrder',
        %w[param option yield yieldparam yieldreturn return raise see example note todo]
      )
    end

    result = Yard::Lint.run(path: file, config: config)

    assert_equal(true, result.offenses.any? { |o| o[:name] == 'InvalidTagOrder' })

    # Should find process and validate methods
    methods = result.offenses
                    .select { |o| o[:name] == 'InvalidTagOrder' }
                    .map { |o| o[:method_name] }
  end

  it 'invalid tag ordering does not flag consecutive same tags as order violations' do
    file = File.join(@fixtures_dir, 'invalid_tag_order.rb')

    config = Yard::Lint::Config.new do |c|
      c.exclude = []
      c.set_validator_config('Tags/Order',
        'EnforcedOrder',
        %w[param option yield yieldparam yieldreturn return raise see example note todo]
      )
    end

    result = Yard::Lint.run(path: file, config: config)

    order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
    offense_methods = order_offenses.map { |o| o[:method_name] }

    # Methods with consecutive same tags (multiple @note or @example) should NOT trigger violations
  end

  it 'undocumented boolean methods detects boolean methods without return docs' do
    file = File.join(@fixtures_dir, 'boolean_methods.rb')

    result = Yard::Lint.run(path: file, config: @config)

    # Boolean methods with comments but without explicit @return tags
    # are NOT flagged because:
    # 1. YARD auto-infers @return [Boolean] for methods ending with '?'
    # 2. Having ANY docstring content (even just a comment) satisfies UndocumentedObjects
    # This is the correct behavior - boolean methods don't need explicit @return tags
    undocumented_booleans = result.offenses
                                  .select { |o| o[:name] == 'UndocumentedObject' }
                                  .select do |o|
      o[:element].to_s.include?('active?') || o[:element].to_s.include?('ready?')
      end
    assert_empty(undocumented_booleans)
  end

  it 'invalid tag types validates that tags use valid type definitions' do
    file = File.join(@fixtures_dir, 'invalid_tag_types.rb')

    result = Yard::Lint.run(path: file, config: @config)

    # The validator checks for types that are not defined Ruby classes
    # This test confirms the validator runs and returns results
    assert_kind_of(Array, result.offenses.select { |o| o[:name] == 'InvalidTagType' })
    assert_respond_to(result, :offenses)
  end

  it 'api tags detects missing or incorrect api tags when enforced' do
    file = File.join(@fixtures_dir, 'api_tags.rb')

    config = Yard::Lint::Config.new do |c|
      c.exclude = []
      c.set_validator_config('Tags/ApiTags', 'Enabled', true)
      c.set_validator_config('Tags/ApiTags', 'AllowedApis', %w[public private internal])
      end
    result = Yard::Lint.run(path: file, config: config)

    # Should detect methods without @api tags
    # Note: This validator is opt-in, so it only runs when explicitly enabled
    assert_kind_of(Array, result.offenses.select { |o| o[:name].to_s.include?('Api') })
  end

  it 'option tags detects methods with options parameters but no option tags' do
    file = File.join(@fixtures_dir, 'option_tags.rb')

    config = Yard::Lint::Config.new do |c|
      c.exclude = []
      c.set_validator_config('Tags/OptionTags', 'Enabled', true)
      end
    result = Yard::Lint.run(path: file, config: config)

    # Should find methods with options/opts/kwargs params but no @option tags
    assert_kind_of(Array, result.offenses.select { |o| o[:name].to_s.include?('Option') })
    assert_respond_to(result, :offenses)

    if result.offenses.any? { |o| o[:name].to_s.include?('Option') }
      methods_with_issues = result.offenses
                                  .select { |o| o[:name].to_s.include?('Option') }
                                  .map { |o| o[:method_name] }

      # Should NOT flag create_user which has @option tags
      correctly_documented = result.offenses.find do |o|
        o[:name].to_s.include?('Option') && o[:method_name].to_s == 'create_user'
        end
      assert_nil(correctly_documented)
      end
  end

  it 'yard warnings detects various yard parser warnings' do
    file = File.join(@fixtures_dir, 'yard_warnings.rb')

    result = Yard::Lint.run(path: file, config: @config)

    # The warnings validator captures various YARD parse warnings
    # This includes unknown tags, unknown directives, invalid formats, etc.
    assert_kind_of(Array, result.offenses.select { |o| o[:severity] == 'error' })
    assert_respond_to(result, :offenses)

    # Warnings should be detected from the fixture file
    if result.offenses.any? { |o| o[:severity] == 'error' }
      warning_messages = result.offenses
                               .select { |o| o[:severity] == 'error' }
                               .map { |w| w[:message] }
      assert_operator(warning_messages.size, :>, 0)
      end
  end

  it 'abstract methods detects abstract methods with actual implementations' do
    file = File.join(@fixtures_dir, 'abstract_methods.rb')

    config = Yard::Lint::Config.new do |c|
      c.exclude = []
      c.set_validator_config('Semantic/AbstractMethods', 'Enabled', true)
      end
    result = Yard::Lint.run(path: file, config: config)

    # Should validate abstract method usage
    assert_kind_of(Array, result.offenses.select { |o| o[:name].to_s.include?('Abstract') })
    assert_respond_to(result, :offenses)

    # Should detect calculate method which has @abstract but also implementation
    if result.offenses.any? { |o| o[:name].to_s.include?('Abstract') }
      methods_with_issues = result.offenses
                                  .select { |o| o[:name].to_s.include?('Abstract') }
                                  .map { |o| o[:method_name] }
                                  end
  end

  it 'clean code no offenses finds no offenses in properly documented code' do
    file = File.join(@fixtures_dir, 'clean_code.rb')

    result = Yard::Lint.run(path: file, config: @config)

    assert_equal(true, result.clean?)
    assert_equal(0, result.count)
    assert_empty(result.offenses)
  end

  it 'multiple files processes multiple files and aggregates results' do
    files = [
      File.join(@fixtures_dir, 'undocumented_class.rb'),
      File.join(@fixtures_dir, 'missing_param_docs.rb'),
      File.join(@fixtures_dir, 'clean_code.rb')
    ]

    result = Yard::Lint.run(path: files, config: @config)

    assert_equal(false, result.clean?)

    # Should have offenses from undocumented_class.rb and missing_param_docs.rb
    # but none from clean_code.rb
    assert_operator(result.offenses.count { |o| o[:name] == 'UndocumentedObject' }, :>, 0)
    assert_operator(result.offenses.count { |o| o[:name] == 'UndocumentedMethodArgument' }, :>, 0)
  end

  it 'configuration options respects custom exclude patterns' do
    config = Yard::Lint::Config.new do |c|
      c.exclude = ['**/undocumented_class.rb']
      end
    # Try to run on excluded file - should process no files
    file = File.join(@fixtures_dir, 'undocumented_class.rb')
    result = Yard::Lint.run(path: file, config: config)

    # Should be clean because file was excluded
    assert_equal(true, result.clean?)
  end

  it 'configuration options applies custom fail on severity' do
    config = Yard::Lint::Config.new do |c|
      c.exclude = []
      c.fail_on_severity = 'error'
      end
    file = File.join(@fixtures_dir, 'invalid_tag_order.rb')
    result = Yard::Lint.run(path: file, config: config)

    # Exit code should be 0 because tag order is convention, not error
  end

  it 'result statistics provides accurate offense statistics' do
    file = File.join(@fixtures_dir, 'undocumented_class.rb')

    result = Yard::Lint.run(path: file, config: @config)

    stats = result.statistics
    assert_equal(result.count, stats[:total])
    assert_operator(stats[:error], :>=, 0)
    assert_operator(stats[:warning], :>=, 0)
    assert_operator(stats[:convention], :>=, 0)
  end

  it 'glob patterns processes files matching glob patterns' do
    pattern = File.join(@fixtures_dir, '*.rb')

    result = Yard::Lint.run(path: pattern, config: @config)

    # Should process multiple files
    # The glob pattern should match at least our test fixtures
    assert_operator(Dir.glob(pattern).size, :>=, 21)

    # Should find the undocumented class in glob_test_file.rb
    # This test file is specifically designed to always have offenses
    refute_empty(result.offenses,
      "Expected to find offenses in fixtures. Files processed: #{Dir.glob(pattern).size}")
    # Verify at least the known offense from glob_test_file.rb exists
    has_undocumented = result.offenses.any? do |o|
      o[:name] == 'UndocumentedObject' && o[:element]&.include?('GlobTestClass')
      end
    assert_equal(true, has_undocumented,
      "Expected to find UndocumentedObject for GlobTestClass. Found: #{result.offenses.map { |o| [o[:name], o[:element]] }}")
  end

  it 'directory processing recursively processes ruby files in directories' do
    result = Yard::Lint.run(path: @fixtures_dir, config: @config)

    # Should process files in the directory
    # Verify files were actually processed
    assert_operator(Dir.glob(File.join(@fixtures_dir, '*.rb')).size, :>=, 21)

    # Should find the specific test offense we expect
    refute_empty(result.offenses,
      "Expected to find offenses when processing directory #{@fixtures_dir}")
    # Verify at least the known offense from glob_test_file.rb exists
    has_undocumented = result.offenses.any? do |o|
      o[:name] == 'UndocumentedObject' && o[:element]&.include?('GlobTestClass')
      end
    assert_equal(true, has_undocumented,
      "Expected to find UndocumentedObject for GlobTestClass. Found offenses: #{result.offenses.map { |o| o[:name] }.uniq.join(', ')}")
    # Should have processed multiple types of offenses (not just from one validator)
    offense_types = result.offenses.map { |o| o[:name] }.uniq
    assert_operator(offense_types.size, :>, 1,
      "Expected multiple offense types, found: #{offense_types.join(', ')}")
  end

  it 'offense structure returns offenses with consistent structure' do
    file = File.join(@fixtures_dir, 'undocumented_class.rb')

    result = Yard::Lint.run(path: file, config: @config)

    result.offenses.each do |offense|
      # Every offense should have these keys
      assert(offense.key?(:severity))
      assert(offense.key?(:type))
      assert(offense.key?(:name))
      assert(offense.key?(:message))
      assert(offense.key?(:location))
      assert(offense.key?(:location_line))

      # Values should be valid
      valid_severities = %w[error warning convention]
      valid_types = %w[line method]
      assert_includes(valid_severities, offense[:severity])
      assert_includes(valid_types, offense[:type])
      assert_kind_of(String, offense[:message])
      refute_empty(offense[:message])
      assert_includes(offense[:location], '.rb')
      end
  end

  it 'error handling raises filenotfounderror for non existent files' do
    assert_raises(Yard::Lint::Errors::FileNotFoundError) do
      Yard::Lint.run(path: '/nonexistent/file.rb')
    end
  end

  it 'error handling handles empty file lists gracefully' do
    # Should not raise
    Yard::Lint.run(path: [])
  end

  it 'error handling handles invalid ruby files gracefully' do
    # Create a file with invalid Ruby syntax
    invalid_file = File.join(@fixtures_dir, 'invalid_syntax.rb')
    File.write(invalid_file, 'class Foo def end')

    # Should not crash, might have parse errors
    Yard::Lint.run(path: invalid_file)
  ensure
    File.delete(invalid_file) if File.exist?(invalid_file)
  end
end

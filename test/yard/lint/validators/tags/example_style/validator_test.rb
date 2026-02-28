# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsExampleStyleValidatorClassConfigTest < Minitest::Test
  def test_enables_in_process_execution
    assert(Yard::Lint::Validators::Tags::ExampleStyle::Validator.in_process?)
  end

  def test_uses_all_visibility
    assert_equal(:all, Yard::Lint::Validators::Tags::ExampleStyle::Validator.in_process_visibility)
  end

  def test_inherits_from_base_validator
    assert_equal(Yard::Lint::Validators::Base, Yard::Lint::Validators::Tags::ExampleStyle::Validator.superclass)
  end
end

class YardLintValidatorsTagsExampleStyleValidatorNoTagsTest < Minitest::Test
  attr_reader :config, :validator, :collector

  def setup
    @config = Yard::Lint::Config.new
    @validator = Yard::Lint::Validators::Tags::ExampleStyle::Validator.new(config, [])
    @collector = stub('collector')
  end

  def test_does_not_output_anything_when_object_has_no_example_tags
    object = stub('object', has_tag?: false)

    collector.expects(:puts).never
    validator.in_process_query(object, collector)
  end
end

class YardLintValidatorsTagsExampleStyleValidatorNoLinterTest < Minitest::Test
  attr_reader :config, :validator, :collector

  def setup
    @config = Yard::Lint::Config.new
    @validator = Yard::Lint::Validators::Tags::ExampleStyle::Validator.new(config, [])
    @collector = stub('collector')
  end

  def test_returns_early_without_processing_when_no_linter_is_available
    object = stub('object', has_tag?: true, tags: [])

    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:detect).returns(:none)

    collector.expects(:puts).never
    validator.in_process_query(object, collector)
  end
end

class YardLintValidatorsTagsExampleStyleValidatorWithLinterTest < Minitest::Test
  attr_reader :config, :validator, :collector, :example_tag, :object

  def setup
    @config = Yard::Lint::Config.new
    @validator = Yard::Lint::Validators::Tags::ExampleStyle::Validator.new(config, [])
    @collector = stub('collector', puts: nil)
    @example_tag = stub('example', text: 'user = User.new', name: 'Basic usage')
    @object = stub(
      'object',
      has_tag?: true,
      tags: [example_tag],
      file: 'lib/user.rb',
      line: 10,
      title: 'User#initialize'
    )
    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:detect).returns(:rubocop)
  end

  def test_processes_examples_and_outputs_offenses
    runner = stub('runner')
    offenses = [
      {
        cop_name: 'Style/StringLiterals',
        message: 'Prefer single-quoted strings',
        line: 1,
        column: 10,
        severity: 'convention'
      }
    ]

    Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner.stubs(:new).returns(runner)
    runner.stubs(:run).returns(offenses)

    collector.expects(:puts).with('lib/user.rb:10: User#initialize')
    collector.expects(:puts).with('style_offense')
    collector.expects(:puts).with('Basic usage')
    collector.expects(:puts).with('Style/StringLiterals')
    collector.expects(:puts).with('Prefer single-quoted strings')

    validator.in_process_query(object, collector)
  end

  def test_uses_default_example_name_when_name_is_nil
    unnamed_example = stub('example', text: 'user = User.new', name: nil)
    obj = stub(
      'object',
      has_tag?: true,
      tags: [unnamed_example],
      file: 'lib/user.rb',
      line: 10,
      title: 'User#initialize'
    )

    runner = stub('runner')
    Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner.stubs(:new).returns(runner)
    runner.stubs(:run).with('user = User.new', 'Example 1', file_path: 'lib/user.rb').returns([])

    validator.in_process_query(obj, collector)
  end

  def test_skips_examples_with_nil_or_empty_code
    nil_example = stub('example', text: nil, name: 'Nil example')
    empty_example = stub('example', text: '', name: 'Empty example')
    obj = stub(
      'object',
      has_tag?: true,
      tags: [nil_example, empty_example],
      file: 'lib/user.rb',
      line: 10,
      title: 'User#initialize'
    )

    runner = stub('runner')
    Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner.stubs(:new).returns(runner)

    runner.expects(:run).never
    validator.in_process_query(obj, collector)
  end

  def test_passes_configuration_to_runner
    config_hash = {
      'Tags/ExampleStyle' => {
        'DisabledCops' => ['Style/FrozenStringLiteralComment'],
        'SkipPatterns' => ['/skip-lint/i']
      }
    }
    local_config = Yard::Lint::Config.new(config_hash)
    local_validator = Yard::Lint::Validators::Tags::ExampleStyle::Validator.new(local_config, [])

    runner = stub('runner')
    runner.stubs(:run).returns([])

    Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner.expects(:new).with do |**kwargs|
      kwargs[:linter] == :rubocop &&
        kwargs[:disabled_cops].include?('Style/FrozenStringLiteralComment')
    end.returns(runner)

    local_validator.in_process_query(object, collector)
  end
end

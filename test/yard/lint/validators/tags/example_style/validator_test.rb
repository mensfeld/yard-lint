# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Validators::Tags::ExampleStyle::Validator' do
  it 'enables in process execution' do
    assert(Yard::Lint::Validators::Tags::ExampleStyle::Validator.in_process?)
  end

  it 'uses all visibility' do
    assert_equal(:all, Yard::Lint::Validators::Tags::ExampleStyle::Validator.in_process_visibility)
  end

  it 'inherits from base validator' do
    assert_equal(Yard::Lint::Validators::Base, Yard::Lint::Validators::Tags::ExampleStyle::Validator.superclass)
  end
end

describe 'YardLintValidatorsTagsExampleStyleValidatorNoTags' do
  attr_reader :config, :validator, :collector

  before do
    @config = Yard::Lint::Config.new
    @validator = Yard::Lint::Validators::Tags::ExampleStyle::Validator.new(config, [])
    @collector = stub('collector')
  end

  it 'does not output anything when object has no example tags' do
    object = stub('object', has_tag?: false)

    collector.expects(:puts).never
    validator.in_process_query(object, collector)
  end
end

describe 'YardLintValidatorsTagsExampleStyleValidatorNoLinter' do
  attr_reader :config, :validator, :collector

  before do
    @config = Yard::Lint::Config.new
    @validator = Yard::Lint::Validators::Tags::ExampleStyle::Validator.new(config, [])
    @collector = stub('collector')
  end

  it 'returns early without processing when no linter is available' do
    object = stub('object', has_tag?: true, tags: [])

    Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.stubs(:detect).returns(:none)

    collector.expects(:puts).never
    validator.in_process_query(object, collector)
  end
end

describe 'YardLintValidatorsTagsExampleStyleValidatorWithLinter' do
  attr_reader :config, :validator, :collector, :example_tag, :object

  before do
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

  it 'processes examples and outputs offenses' do
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

  it 'uses default example name when name is nil' do
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

  it 'skips examples with nil or empty code' do
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

  it 'passes configuration to runner' do
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


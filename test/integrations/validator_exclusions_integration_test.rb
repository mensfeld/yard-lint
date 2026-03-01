# frozen_string_literal: true

require 'test_helper'


describe 'Validator Exclusions Integration' do
  attr_reader :config

  before do
    YARD::Registry.clear
  end

  def project_path(relative_path)
    File.expand_path("../../#{relative_path}", __dir__)
  end

  # -- ExampleSyntax with Exclude patterns --

  def setup_example_syntax_with_exclusions
    @config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Tags/ExampleSyntax', 'Enabled', true)
      c.set_validator_config('Tags/ExampleSyntax', 'Severity', 'error')

      c.set_validator_config(
        'Tags/ExampleSyntax',
        'Exclude',
        [
          '**/validators/**/parser.rb',
          'test/fixtures/**/*'
        ]
      )
    end
  end

  it 'per validator exclusions when tags examplesyntax has exclude patterns excludes parser rb files' do
    setup_example_syntax_with_exclusions

    result = Yard::Lint.run(path: project_path('lib/yard/lint/validators'), config: config)

    parser_offenses = result.offenses.select do |o|
      o[:name] == 'ExampleSyntax' && o[:location].end_with?('parser.rb')
    end

    assert_empty(parser_offenses)
  end

  it 'per validator exclusions when tags examplesyntax has exclude patterns excludes spec fixtures files' do
    setup_example_syntax_with_exclusions

    result = Yard::Lint.run(path: project_path('test/fixtures'), config: config)

    fixture_offenses = result.offenses.select do |o|
      o[:name] == 'ExampleSyntax' && o[:location].include?('test/fixtures')
    end

    assert_empty(fixture_offenses)
  end

  it 'per validator exclusions when tags examplesyntax has exclude patterns still validates other files' do
    setup_example_syntax_with_exclusions

    result = Yard::Lint.run(path: project_path('lib/yard/lint/stats_calculator.rb'), config: config)

    assert_respond_to(result, :offenses)
    assert_kind_of(Array, result.offenses)
  end

  # -- Combining global and per-validator exclusions --

  it 'per validator exclusions when combining global and per validator exclusions applies both' do
    @config = Yard::Lint::Config.new do |c|
      c.exclude = ['spec/**/*', 'test/**/*']

      c.set_validator_config('Documentation/UndocumentedObjects', 'Enabled', true)
      c.set_validator_config(
        'Documentation/UndocumentedObjects',
        'Exclude',
        [
          'lib/yard/lint/validators/**/*.rb'
        ]
      )
    end

    result = Yard::Lint.run(path: project_path('lib'), config: config)

    spec_offenses = result.offenses.select { |o| o[:location].include?('spec/') }
    assert_empty(spec_offenses)

    validator_offenses = result.offenses.select do |o|
      o[:name] == 'UndocumentedObject' &&
        o[:location].include?('lib/yard/lint/validators/') &&
        o[:location].end_with?('.rb')
    end
    assert_empty(validator_offenses)
  end

  # -- No exclusions set --

  it 'per validator exclusions when no exclusions are set validates all files including parser rb files' do
    @config = Yard::Lint::Config.new do |c|
      c.exclude = []
      c.set_validator_config('Tags/ExampleSyntax', 'Enabled', true)
    end

    result = Yard::Lint.run(
      path: project_path('lib/yard/lint/validators/documentation/undocumented_method_arguments/parser.rb'),
      config: config
    )

    parser_offenses = result.offenses.select do |o|
      o[:name] == 'ExampleSyntax' && o[:location].end_with?('parser.rb')
    end

    refute_empty(parser_offenses)
  end

  # -- Glob patterns --

  it 'exclusion pattern matching with glob patterns matches files with glob pattern' do
    @config = Yard::Lint::Config.new do |c|
      c.exclude = ['spec/**/*', 'test/**/*']
      c.set_validator_config('Documentation/UndocumentedObjects', 'Enabled', true)
      c.set_validator_config(
        'Documentation/UndocumentedObjects',
        'Exclude',
        [
          'lib/yard/lint/validators/**/*.rb'
        ]
      )
    end

    result = Yard::Lint.run(path: project_path('lib/yard/lint/validators'), config: config)

    validator_offenses = result.offenses.select do |o|
      o[:name] == 'UndocumentedObject' &&
        o[:location].include?('lib/yard/lint/validators/') &&
        o[:location].end_with?('.rb')
    end

    assert_empty(validator_offenses)
  end

  # -- Wildcard patterns --

  it 'exclusion pattern matching with wildcard patterns matches files with wildcard pattern' do
    @config = Yard::Lint::Config.new do |c|
      c.exclude = ['spec/**/*', 'test/**/*']
      c.set_validator_config('Documentation/UndocumentedObjects', 'Enabled', true)
      c.set_validator_config(
        'Documentation/UndocumentedObjects',
        'Exclude',
        [
          '**/lint/config.rb'
        ]
      )
    end

    result = Yard::Lint.run(path: project_path('lib/yard/lint/config.rb'), config: config)

    config_offenses = result.offenses.select do |o|
      o[:name] == 'UndocumentedObject' &&
        o[:location].end_with?('config.rb')
    end

    assert_empty(config_offenses)
  end
end

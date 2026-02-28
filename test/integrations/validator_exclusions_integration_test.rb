# frozen_string_literal: true

require 'test_helper'

class ValidatorExclusionsIntegrationTest < Minitest::Test
  attr_reader :config

  def setup
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

  def test_per_validator_exclusions_when_tags_examplesyntax_has_exclude_patterns_excludes_parser_rb_files
    setup_example_syntax_with_exclusions

    result = Yard::Lint.run(path: project_path('lib/yard/lint/validators'), config: config)

    parser_offenses = result.offenses.select do |o|
      o[:name] == 'ExampleSyntax' && o[:location].end_with?('parser.rb')
    end

    assert_empty(parser_offenses)
  end

  def test_per_validator_exclusions_when_tags_examplesyntax_has_exclude_patterns_excludes_spec_fixtures_files
    setup_example_syntax_with_exclusions

    result = Yard::Lint.run(path: project_path('test/fixtures'), config: config)

    fixture_offenses = result.offenses.select do |o|
      o[:name] == 'ExampleSyntax' && o[:location].include?('test/fixtures')
    end

    assert_empty(fixture_offenses)
  end

  def test_per_validator_exclusions_when_tags_examplesyntax_has_exclude_patterns_still_validates_other_files
    setup_example_syntax_with_exclusions

    result = Yard::Lint.run(path: project_path('lib/yard/lint/stats_calculator.rb'), config: config)

    assert_respond_to(result, :offenses)
    assert_kind_of(Array, result.offenses)
  end

  # -- Combining global and per-validator exclusions --

  def test_per_validator_exclusions_when_combining_global_and_per_validator_exclusions_applies_both
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

  def test_per_validator_exclusions_when_no_exclusions_are_set_validates_all_files_including_parser_rb_files
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

  def test_exclusion_pattern_matching_with_glob_patterns_matches_files_with_glob_pattern
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

  def test_exclusion_pattern_matching_with_wildcard_patterns_matches_files_with_wildcard_pattern
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

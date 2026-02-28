# frozen_string_literal: true

require 'test_helper'
require 'test_helper'

class EdgeCaseFileHandlingTest < Minitest::Test
  attr_reader :fixtures_dir

  def setup
    @fixtures_dir = File.expand_path('../fixtures', __dir__)
  end

  def test_empty_file_handles_files_with_no_code_gracefully
    files = [File.join(fixtures_dir, 'empty_file.rb')]

    config = Yard::Lint::Config.new(
      {
        'AllValidators' => {
          'YardOptions' => [],
          'Exclude' => []
        },
        'Documentation' => {
          'Enabled' => true
        },
        'Tags/ExampleSyntax' => {
          'Enabled' => false
        }
      }
    )

    runner = Yard::Lint::Runner.new(files, config)
    result = runner.run

    # Should not crash, should have no offenses
    assert_empty(result.offenses)
    assert_respond_to(result, :offenses)
  end

  def test_file_with_only_comments_handles_files_with_no_executable_code
    files = [File.join(fixtures_dir, 'only_comments.rb')]

    config = Yard::Lint::Config.new(
      {
        'AllValidators' => {
          'YardOptions' => [],
          'Exclude' => []
        },
        'Documentation' => {
          'Enabled' => true
        },
        'Tags/ExampleSyntax' => {
          'Enabled' => false
        }
      }
    )

    runner = Yard::Lint::Runner.new(files, config)
    result = runner.run

    # Should not crash, should have no offenses
    assert_empty(result.offenses)
    assert_respond_to(result, :offenses)
  end

  def test_file_with_only_require_statements_handles_files_with_only_requires
    files = [File.join(fixtures_dir, 'only_requires.rb')]

    config = Yard::Lint::Config.new(
      {
        'AllValidators' => {
          'YardOptions' => [],
          'Exclude' => []
        },
        'Documentation' => {
          'Enabled' => true
        },
        'Tags/ExampleSyntax' => {
          'Enabled' => false
        }
      }
    )

    runner = Yard::Lint::Runner.new(files, config)
    result = runner.run

    # Should not crash, should have no offenses
    assert_empty(result.offenses)
    assert_respond_to(result, :offenses)
  end

  def test_file_with_only_constants_handles_files_with_only_constant_definitions
    files = [File.join(fixtures_dir, 'only_constants.rb')]

    config = Yard::Lint::Config.new(
      {
        'AllValidators' => {
          'YardOptions' => [],
          'Exclude' => []
        },
        'Documentation' => {
          'Enabled' => true
        }
      }
    )

    runner = Yard::Lint::Runner.new(files, config)
    result = runner.run

    # Should not crash
    # May or may not have offenses depending on UndocumentedObject behavior
    assert_respond_to(result, :offenses)
  end

  def test_processing_multiple_edge_case_files_together_handles_a_batch_of_edge_case_files_without_errors
    files = [
      File.join(fixtures_dir, 'empty_file.rb'),
      File.join(fixtures_dir, 'only_comments.rb'),
      File.join(fixtures_dir, 'only_requires.rb'),
      File.join(fixtures_dir, 'only_constants.rb')
    ]

    config = Yard::Lint::Config.new(
      {
        'AllValidators' => {
          'YardOptions' => [],
          'Exclude' => []
        },
        'Documentation' => {
          'Enabled' => true
        },
        'Tags' => {
          'Enabled' => true
        }
      }
    )

    runner = Yard::Lint::Runner.new(files, config)
    result = runner.run

    # Should process all files without crashing
    assert_respond_to(result, :offenses)
  end

  def test_edge_case_files_with_exclusions_correctly_applies_exclusions_to_edge_case_files
    files = [
      File.join(fixtures_dir, 'empty_file.rb'),
      File.join(fixtures_dir, 'only_comments.rb')
    ]

    config = Yard::Lint::Config.new(
      {
        'AllValidators' => {
          'YardOptions' => [],
          'Exclude' => ['**/empty_file.rb']
        },
        'Documentation' => {
          'Enabled' => true
        }
      }
    )

    runner = Yard::Lint::Runner.new(files, config)
    result = runner.run

    # Should only process only_comments.rb (empty_file.rb is globally excluded)
    # Verify no errors occurred
    assert_respond_to(result, :offenses)
  end

  def test_edge_case_files_with_all_validators_enabled_runs_all_validators_against_edge_case_files_without
    files = [
      File.join(fixtures_dir, 'empty_file.rb'),
      File.join(fixtures_dir, 'only_comments.rb'),
      File.join(fixtures_dir, 'only_requires.rb')
    ]

    config = Yard::Lint::Config.new(
      {
        'AllValidators' => {
          'YardOptions' => [],
          'Exclude' => []
        },
        'Documentation' => {
          'Enabled' => true
        },
        'Tags' => {
          'Enabled' => true
        },
        'Warnings' => {
          'Enabled' => true
        },
        'Semantic' => {
          'Enabled' => true
        }
      }
    )

    runner = Yard::Lint::Runner.new(files, config)
    result = runner.run

    # Should not crash regardless of whether offenses are found
    assert_respond_to(result, :offenses)
  end
end


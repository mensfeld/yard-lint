# frozen_string_literal: true

require 'test_helper'


describe 'Edge Case Files' do
  attr_reader :fixtures_dir


  before do
    @fixtures_dir = File.expand_path('../fixtures', __dir__)
  end

  it 'empty file handles files with no code gracefully' do
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

  it 'file with only comments handles files with no executable code' do
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

  it 'file with only require statements handles files with only requires' do
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

  it 'file with only constants handles files with only constant definitions' do
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

  it 'processing multiple edge case files together handles a batch of edge case files without errors' do
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

  it 'edge case files with exclusions correctly applies exclusions to edge case files' do
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

  it 'edge case files with all validators enabled runs all validators against edge case files without' do
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


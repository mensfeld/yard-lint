# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsExampleStyleRubocopRunnerSkipPatternsTest < Minitest::Test
  attr_reader :runner

  def setup
    @runner = Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner.new(
      linter: :rubocop,
      disabled_cops: [],
      skip_patterns: ['/skip-lint/i', '/bad code/i']
    )
  end

  def test_skips_examples_matching_skip_patterns_case_insensitive
    result = runner.run('user = User.new', 'Bad code (skip-lint)')
    assert_equal([], result)
  end

  def test_skips_examples_matching_alternative_pattern
    result = runner.run('user = User.new', 'Example showing bad code')
    assert_equal([], result)
  end

  def test_does_not_skip_examples_that_do_not_match_patterns
    status = stub('status', success?: true)
    Open3.stubs(:capture3).returns(['{"files":[]}', '', status])
    result = runner.run('user = User.new', 'Valid example')
    assert_equal([], result)
  end
end

class YardLintValidatorsTagsExampleStyleRubocopRunnerCodeCleaningTest < Minitest::Test
  attr_reader :runner

  def setup
    @runner = Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner.new(linter: :rubocop, disabled_cops: [], skip_patterns: [])
  end

  def test_removes_output_indicators
    code = <<~RUBY
      result = User.new
      result.name  # => "John"
    RUBY

    expected_cleaned_code = "result = User.new\nresult.name"

    status = stub('status', success?: true)
    Open3.expects(:capture3).with do |*_args, **kwargs|
      assert_equal(expected_cleaned_code.strip, kwargs[:stdin_data].strip)
      true
    end.returns(['{"files":[]}', '', status])

    runner.run(code, 'Example')
  end

  def test_returns_empty_array_for_empty_code
    result = runner.run('', 'Example')
    assert_equal([], result)
  end

  def test_returns_empty_array_for_nil_code
    result = runner.run(nil, 'Example')
    assert_equal([], result)
  end

  def test_returns_empty_array_for_whitespace_only_code
    result = runner.run("   \n  \n  ", 'Example')
    assert_equal([], result)
  end
end

class YardLintValidatorsTagsExampleStyleRubocopRunnerRubocopLinterTest < Minitest::Test
  attr_reader :runner

  def setup
    @runner = Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner.new(
      linter: :rubocop,
      disabled_cops: ['Style/FrozenStringLiteralComment'],
      skip_patterns: []
    )
  end

  def test_runs_rubocop_with_disabled_cops
    code = 'user = User.new'

    status = stub('status', success?: true)
    Open3.expects(:capture3).with do |*args, **_kwargs|
      args.include?('rubocop') &&
        args.include?('--format') &&
        args.include?('json') &&
        args.include?('--stdin') &&
        args.include?('example.rb') &&
        args.include?('--except') &&
        args.include?('Style/FrozenStringLiteralComment')
    end.returns(['{"files":[]}', '', status])

    runner.run(code, 'Example')
  end

  def test_parses_rubocop_json_output_correctly
    code = 'user = User.new'
    rubocop_output = {
      'files' => [
        {
          'offenses' => [
            {
              'cop_name' => 'Style/StringLiterals',
              'message' => 'Prefer single-quoted strings',
              'severity' => 'convention',
              'location' => { 'line' => 1, 'column' => 10 }
            }
          ]
        }
      ]
    }.to_json

    status = stub('status', success?: true)
    Open3.stubs(:capture3).returns([rubocop_output, '', status])

    result = runner.run(code, 'Example')
    assert_equal([
      {
        cop_name: 'Style/StringLiterals',
        message: 'Prefer single-quoted strings',
        line: 1,
        column: 10,
        severity: 'convention'
      }
    ], result)
  end

  def test_handles_empty_rubocop_output
    status = stub('status', success?: true)
    Open3.stubs(:capture3).returns(['', '', status])
    result = runner.run('user = User.new', 'Example')
    assert_equal([], result)
  end

  def test_handles_missing_rubocop_command
    Open3.stubs(:capture3).raises(Errno::ENOENT)
    result = runner.run('user = User.new', 'Example')
    assert_equal([], result)
  end
end

class YardLintValidatorsTagsExampleStyleRubocopRunnerStandardRBLinterTest < Minitest::Test
  attr_reader :runner

  def setup
    @runner = Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner.new(
      linter: :standard,
      disabled_cops: [],
      skip_patterns: []
    )
  end

  def test_runs_standardrb_command
    code = 'user = User.new'

    status = stub('status', success?: true)
    Open3.expects(:capture3).with do |*args, **_kwargs|
      args.include?('standardrb') &&
        args.include?('--format') &&
        args.include?('json') &&
        args.include?('--stdin') &&
        args.include?('example.rb')
    end.returns(['{"files":[]}', '', status])

    runner.run(code, 'Example')
  end

  def test_parses_standardrb_json_output_correctly
    code = 'user = User.new'
    standard_output = {
      'files' => [
        {
          'offenses' => [
            {
              'cop_name' => 'Style/StringLiterals',
              'message' => 'Prefer single-quoted strings',
              'severity' => 'convention',
              'location' => { 'line' => 1, 'column' => 10 }
            }
          ]
        }
      ]
    }.to_json

    status = stub('status', success?: true)
    Open3.stubs(:capture3).returns([standard_output, '', status])

    result = runner.run(code, 'Example')
    assert_equal([
      {
        cop_name: 'Style/StringLiterals',
        message: 'Prefer single-quoted strings',
        line: 1,
        column: 10,
        severity: 'convention'
      }
    ], result)
  end

  def test_handles_missing_standardrb_command
    Open3.stubs(:capture3).raises(Errno::ENOENT)
    result = runner.run('user = User.new', 'Example')
    assert_equal([], result)
  end
end

class YardLintValidatorsTagsExampleStyleRubocopRunnerErrorHandlingTest < Minitest::Test
  attr_reader :runner

  def setup
    @runner = Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner.new(linter: :rubocop, disabled_cops: [], skip_patterns: [])
  end

  def test_handles_json_parse_errors_gracefully
    status = stub('status', success?: true)
    Open3.stubs(:capture3).returns(['invalid json', '', status])
    result = runner.run('user = User.new', 'Example')
    assert_equal([], result)
  end

  def test_handles_general_errors_gracefully
    Open3.stubs(:capture3).raises(StandardError.new('Something went wrong'))
    result = runner.run('user = User.new', 'Example')
    assert_equal([], result)
  end
end

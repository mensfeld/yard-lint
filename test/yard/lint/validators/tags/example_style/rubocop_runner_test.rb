# frozen_string_literal: true

describe 'Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner' do
  attr_reader :runner

  before do
    @runner = Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner.new(
      linter: :rubocop,
      disabled_cops: [],
      skip_patterns: ['/skip-lint/i', '/bad code/i']
    )
  end

  it 'skips examples matching skip patterns case insensitive' do
    result = runner.run('user = User.new', 'Bad code (skip-lint)')
    assert_equal([], result)
  end

  it 'skips examples matching alternative pattern' do
    result = runner.run('user = User.new', 'Example showing bad code')
    assert_equal([], result)
  end

  it 'does not skip examples that do not match patterns' do
    status = stub('status', success?: true)
    Open3.stubs(:capture3).returns(['{"files":[]}', '', status])
    result = runner.run('user = User.new', 'Valid example')
    assert_equal([], result)
  end
end

describe 'YardLintValidatorsTagsExampleStyleRubocopRunnerCodeCleaning' do
  attr_reader :runner

  before do
    @runner = Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner.new(linter: :rubocop, disabled_cops: [], skip_patterns: [])
  end

  it 'removes output indicators' do
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

  it 'returns empty array for empty code' do
    result = runner.run('', 'Example')
    assert_equal([], result)
  end

  it 'returns empty array for nil code' do
    result = runner.run(nil, 'Example')
    assert_equal([], result)
  end

  it 'returns empty array for whitespace only code' do
    result = runner.run("   \n  \n  ", 'Example')
    assert_equal([], result)
  end
end

describe 'YardLintValidatorsTagsExampleStyleRubocopRunnerRubocopLinter' do
  attr_reader :runner

  before do
    @runner = Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner.new(
      linter: :rubocop,
      disabled_cops: ['Style/FrozenStringLiteralComment'],
      skip_patterns: []
    )
  end

  it 'runs rubocop with disabled cops' do
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

  it 'parses rubocop json output correctly' do
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

  it 'handles empty rubocop output' do
    status = stub('status', success?: true)
    Open3.stubs(:capture3).returns(['', '', status])
    result = runner.run('user = User.new', 'Example')
    assert_equal([], result)
  end

  it 'handles missing rubocop command' do
    Open3.stubs(:capture3).raises(Errno::ENOENT)
    result = runner.run('user = User.new', 'Example')
    assert_equal([], result)
  end
end

describe 'YardLintValidatorsTagsExampleStyleRubocopRunnerStandardRBLinter' do
  attr_reader :runner

  before do
    @runner = Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner.new(
      linter: :standard,
      disabled_cops: [],
      skip_patterns: []
    )
  end

  it 'runs standardrb command' do
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

  it 'parses standardrb json output correctly' do
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

  it 'handles missing standardrb command' do
    Open3.stubs(:capture3).raises(Errno::ENOENT)
    result = runner.run('user = User.new', 'Example')
    assert_equal([], result)
  end
end

describe 'YardLintValidatorsTagsExampleStyleRubocopRunnerErrorHandling' do
  attr_reader :runner

  before do
    @runner = Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner.new(linter: :rubocop, disabled_cops: [], skip_patterns: [])
  end

  it 'handles json parse errors gracefully' do
    status = stub('status', success?: true)
    Open3.stubs(:capture3).returns(['invalid json', '', status])
    result = runner.run('user = User.new', 'Example')
    assert_equal([], result)
  end

  it 'handles general errors gracefully' do
    Open3.stubs(:capture3).raises(StandardError.new('Something went wrong'))
    result = runner.run('user = User.new', 'Example')
    assert_equal([], result)
  end
end


# frozen_string_literal: true

describe 'Yard::Lint::StatsCalculator' do
  attr_reader :config, :files, :calculator

  before do
    @config = Yard::Lint::Config.new
    @files = ['/path/to/file1.rb', '/path/to/file2.rb']
    @calculator = Yard::Lint::StatsCalculator.new(config, files)
  end

  # #initialize

  it 'initialize stores config and files' do
    assert_equal(config, calculator.config)
    assert_equal(files, calculator.files)
  end

  it 'initialize handles nil files gracefully' do
    calc = Yard::Lint::StatsCalculator.new(config, nil)
    assert_equal([], calc.files)
  end

  # #calculate

  it 'calculate with empty file list returns 100 coverage' do
    empty_calculator = Yard::Lint::StatsCalculator.new(config, [])
    result = empty_calculator.calculate
    assert_equal({ total: 0, documented: 0, coverage: 100.0 }, result)
  end

  it 'calculate with valid yard output calculates correct coverage' do
    yard_output = <<~OUTPUT
      method:doc
      method:doc
      method:undoc
      class:doc
      class:undoc
      module:doc
    OUTPUT
    calculator.stubs(:run_yard_stats_query).returns(yard_output)

    result = calculator.calculate
    # 4 documented (2 methods + 1 class + 1 module) / 6 total = 66.67%
    assert_equal(6, result[:total])
    assert_equal(4, result[:documented])
    assert_in_delta(66.67, result[:coverage], 0.01)
  end

  it 'calculate with all documented objects returns 100 coverage' do
    yard_output = <<~OUTPUT
      method:doc
      class:doc
      module:doc
    OUTPUT
    calculator.stubs(:run_yard_stats_query).returns(yard_output)

    result = calculator.calculate
    assert_equal(3, result[:total])
    assert_equal(3, result[:documented])
    assert_equal(100.0, result[:coverage])
  end

  it 'calculate with all undocumented objects returns 0 coverage' do
    yard_output = <<~OUTPUT
      method:undoc
      class:undoc
    OUTPUT
    calculator.stubs(:run_yard_stats_query).returns(yard_output)

    result = calculator.calculate
    assert_equal(2, result[:total])
    assert_equal(0, result[:documented])
    assert_equal(0.0, result[:coverage])
  end

  it 'calculate when yard command fails returns default stats' do
    calculator.stubs(:run_yard_stats_query).returns('')

    result = calculator.calculate
    assert_equal({ total: 0, documented: 0, coverage: 100.0 }, result)
  end

  # #parse_stats_output

  it 'parse stats output parses valid output correctly' do
    output = <<~OUTPUT
      method:doc
      method:undoc
      method:undoc
      class:doc
      module:undoc
    OUTPUT

    result = calculator.send(:parse_stats_output, output)

    assert_equal({ documented: 1, undocumented: 2 }, result['method'])
    assert_equal({ documented: 1, undocumented: 0 }, result['class'])
    assert_equal({ documented: 0, undocumented: 1 }, result['module'])
  end

  it 'parse stats output handles empty output' do
    result = calculator.send(:parse_stats_output, '')
    assert_equal({}, result)
  end

  it 'parse stats output handles malformed lines gracefully' do
    output = <<~OUTPUT
      method:doc
      invalid_line
      class:doc
    OUTPUT

    result = calculator.send(:parse_stats_output, output)
    assert_includes(result.keys, 'method')
    assert_includes(result.keys, 'class')
    assert_equal(2, result.keys.size)
  end

  it 'parse stats output ignores lines with extra colons' do
    output = "method:doc:extra\n"
    result = calculator.send(:parse_stats_output, output)
    # Line is malformed (extra colon), should be ignored
    # Hash.new returns default value for non-existent keys
    assert_equal({ documented: 0, undocumented: 0 }, result['method'])
  end

  # #calculate_coverage_percentage

  it 'calculate coverage percentage calculates correct percentage' do
    stats = {
      'method' => { documented: 8, undocumented: 2 },
      'class' => { documented: 5, undocumented: 0 }
    }

    result = calculator.send(:calculate_coverage_percentage, stats)

    assert_equal(15, result[:total])
    assert_equal(13, result[:documented])
    assert_in_delta(86.67, result[:coverage], 0.01)
  end

  it 'calculate coverage percentage returns 100 for empty stats' do
    stats = {}
    result = calculator.send(:calculate_coverage_percentage, stats)

    assert_equal(0, result[:total])
    assert_equal(0, result[:documented])
    assert_equal(100.0, result[:coverage])
  end

  it 'calculate coverage percentage handles zero documented objects' do
    stats = {
      'method' => { documented: 0, undocumented: 10 }
    }

    result = calculator.send(:calculate_coverage_percentage, stats)

    assert_equal(10, result[:total])
    assert_equal(0, result[:documented])
    assert_equal(0.0, result[:coverage])
  end

  # #build_stats_query

  it 'build stats query returns valid yard query' do
    query = calculator.send(:build_stats_query)
    assert_includes(query, 'object.type.to_s')
    assert_includes(query, 'object.docstring.all.empty?')
    assert_includes(query, 'doc')
    assert_includes(query, 'undoc')
  end
end


# frozen_string_literal: true

require 'test_helper'

class YardLintStatsCalculatorTest < Minitest::Test
  attr_reader :calculator, :config, :files

  def setup
    @config = Yard::Lint::Config.new
    @files = ['/path/to/file1.rb', '/path/to/file2.rb']
    @calculator = Yard::Lint::StatsCalculator.new(config, files)
  end

  # #initialize

  def test_initialize_stores_config_and_files
    assert_equal(config, calculator.config)
    assert_equal(files, calculator.files)
  end

  def test_initialize_handles_nil_files_gracefully
    calc = Yard::Lint::StatsCalculator.new(config, nil)
    assert_equal([], calc.files)
  end

  # #calculate

  def test_calculate_with_empty_file_list_returns_100_coverage
    empty_calculator = Yard::Lint::StatsCalculator.new(config, [])
    result = empty_calculator.calculate
    assert_equal({ total: 0, documented: 0, coverage: 100.0 }, result)
  end

  def test_calculate_with_valid_yard_output_calculates_correct_coverage
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

  def test_calculate_with_all_documented_objects_returns_100_coverage
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

  def test_calculate_with_all_undocumented_objects_returns_0_coverage
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

  def test_calculate_when_yard_command_fails_returns_default_stats
    calculator.stubs(:run_yard_stats_query).returns('')

    result = calculator.calculate
    assert_equal({ total: 0, documented: 0, coverage: 100.0 }, result)
  end

  # #parse_stats_output

  def test_parse_stats_output_parses_valid_output_correctly
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

  def test_parse_stats_output_handles_empty_output
    result = calculator.send(:parse_stats_output, '')
    assert_equal({}, result)
  end

  def test_parse_stats_output_handles_malformed_lines_gracefully
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

  def test_parse_stats_output_ignores_lines_with_extra_colons
    output = "method:doc:extra\n"
    result = calculator.send(:parse_stats_output, output)
    # Line is malformed (extra colon), should be ignored
    # Hash.new returns default value for non-existent keys
    assert_equal({ documented: 0, undocumented: 0 }, result['method'])
  end

  # #calculate_coverage_percentage

  def test_calculate_coverage_percentage_calculates_correct_percentage
    stats = {
      'method' => { documented: 8, undocumented: 2 },
      'class' => { documented: 5, undocumented: 0 }
    }

    result = calculator.send(:calculate_coverage_percentage, stats)

    assert_equal(15, result[:total])
    assert_equal(13, result[:documented])
    assert_in_delta(86.67, result[:coverage], 0.01)
  end

  def test_calculate_coverage_percentage_returns_100_for_empty_stats
    stats = {}
    result = calculator.send(:calculate_coverage_percentage, stats)

    assert_equal(0, result[:total])
    assert_equal(0, result[:documented])
    assert_equal(100.0, result[:coverage])
  end

  def test_calculate_coverage_percentage_handles_zero_documented_objects
    stats = {
      'method' => { documented: 0, undocumented: 10 }
    }

    result = calculator.send(:calculate_coverage_percentage, stats)

    assert_equal(10, result[:total])
    assert_equal(0, result[:documented])
    assert_equal(0.0, result[:coverage])
  end

  # #build_stats_query

  def test_build_stats_query_returns_valid_yard_query
    query = calculator.send(:build_stats_query)
    assert_includes(query, 'object.type.to_s')
    assert_includes(query, 'object.docstring.all.empty?')
    assert_includes(query, 'doc')
    assert_includes(query, 'undoc')
  end
end

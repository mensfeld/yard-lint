# frozen_string_literal: true

require 'test_helper'

class YardLintResultsAggregateTest < Minitest::Test
  attr_reader :result1, :result2, :result3, :config, :aggregate

  def setup
    @result1 = stub(
      offenses: [
        { severity: 'error', type: 'line', name: 'Error1', message: 'msg1',
          location: 'file1.rb', location_line: 1 },
        { severity: 'warning', type: 'method', name: 'Warning1', message: 'msg2',
          location: 'file2.rb', location_line: 2 }
      ]
    )
    @result2 = stub(
      offenses: [
        { severity: 'convention', type: 'line', name: 'Convention1', message: 'msg3',
          location: 'file3.rb', location_line: 3 }
      ]
    )
    @result3 = stub(offenses: [])
    @config = stub(fail_on_severity: 'warning')
    @aggregate = Yard::Lint::Results::Aggregate.new([@result1, @result2, @result3], @config)
  end

  def test_initialize_accepts_array_of_results
    Yard::Lint::Results::Aggregate.new([@result1, @result2], @config)
  end

  def test_initialize_handles_single_result
    agg = Yard::Lint::Results::Aggregate.new(@result1, @config)
    assert_equal(2, agg.offenses.size)
  end

  def test_initialize_handles_nil_results
    agg = Yard::Lint::Results::Aggregate.new(nil, @config)
    assert_equal([], agg.offenses)
  end

  def test_initialize_handles_empty_array
    agg = Yard::Lint::Results::Aggregate.new([], @config)
    assert_equal([], agg.offenses)
  end

  def test_initialize_stores_config
    assert_equal(@config, @aggregate.config)
  end

  def test_offenses_flattens_all_offenses_from_all_results
    assert_kind_of(Array, @aggregate.offenses)
    assert_equal(3, @aggregate.offenses.size)
  end

  def test_offenses_preserves_offense_structure
    offense = @aggregate.offenses.first
    assert(offense.key?(:severity))
    assert(offense.key?(:type))
    assert(offense.key?(:name))
    assert(offense.key?(:message))
    assert(offense.key?(:location))
    assert(offense.key?(:location_line))
  end

  def test_offenses_includes_offenses_from_all_results
    names = @aggregate.offenses.map { |o| o[:name] }.sort
    assert_equal(%w[Convention1 Error1 Warning1], names)
  end

  def test_count_returns_total_number_of_offenses
    assert_equal(3, @aggregate.count)
  end

  def test_count_returns_0_when_no_offenses
    empty_aggregate = Yard::Lint::Results::Aggregate.new([@result3], @config)
    assert_equal(0, empty_aggregate.count)
  end

  def test_clean_returns_false_when_offenses_exist
    assert_equal(false, @aggregate.clean?)
  end

  def test_clean_returns_true_when_no_offenses
    empty_aggregate = Yard::Lint::Results::Aggregate.new([@result3], @config)
    assert_equal(true, empty_aggregate.clean?)
  end

  def test_statistics_counts_offenses_by_severity
    stats = @aggregate.statistics
    assert_kind_of(Hash, stats)
    assert_equal(1, stats[:error])
    assert_equal(1, stats[:warning])
    assert_equal(1, stats[:convention])
  end

  def test_statistics_initializes_all_severity_counts_to_0
    empty_aggregate = Yard::Lint::Results::Aggregate.new([], @config)
    stats = empty_aggregate.statistics
    assert_equal(0, stats[:error])
    assert_equal(0, stats[:warning])
    assert_equal(0, stats[:convention])
  end

  def test_statistics_handles_multiple_offenses_of_same_severity
    result_with_multiple = stub(
      offenses: [
        { severity: 'error', type: 'line', name: 'Error1', message: 'msg',
          location: 'f.rb', location_line: 1 },
        { severity: 'error', type: 'line', name: 'Error2', message: 'msg',
          location: 'f.rb', location_line: 2 }
      ]
    )
    agg = Yard::Lint::Results::Aggregate.new([result_with_multiple], @config)
    assert_equal(2, agg.statistics[:error])
  end

  # exit_code tests with fail_on_severity = "error"

  def test_exit_code_when_fail_on_severity_is_error_returns_1_if_errors_exist
    error_config = stub(fail_on_severity: 'error', min_coverage: nil)
    agg = Yard::Lint::Results::Aggregate.new([@result1, @result2, @result3], error_config)
    assert_equal(1, agg.exit_code)
  end

  def test_exit_code_when_fail_on_severity_is_error_returns_0_if_only_warnings_exist
    error_config = stub(fail_on_severity: 'error', min_coverage: nil)
    agg = Yard::Lint::Results::Aggregate.new([@result2], error_config)
    assert_equal(0, agg.exit_code)
  end

  def test_exit_code_when_fail_on_severity_is_error_returns_0_if_no_offenses
    error_config = stub(fail_on_severity: 'error', min_coverage: nil)
    agg = Yard::Lint::Results::Aggregate.new([], error_config)
    assert_equal(0, agg.exit_code)
  end

  # exit_code tests with fail_on_severity = "warning"

  def test_exit_code_when_fail_on_severity_is_warning_returns_1_if_errors_exist
    warning_config = stub(fail_on_severity: 'warning', min_coverage: nil)
    agg = Yard::Lint::Results::Aggregate.new([@result1, @result2, @result3], warning_config)
    assert_equal(1, agg.exit_code)
  end

  def test_exit_code_when_fail_on_severity_is_warning_returns_1_if_warnings_exist
    warning_config = stub(fail_on_severity: 'warning', min_coverage: nil)
    warning_result = stub(
      offenses: [
        { severity: 'warning', type: 'line', name: 'Warn', message: 'msg',
          location: 'f.rb', location_line: 1 }
      ]
    )
    agg = Yard::Lint::Results::Aggregate.new([warning_result], warning_config)
    assert_equal(1, agg.exit_code)
  end

  def test_exit_code_when_fail_on_severity_is_warning_returns_0_if_only_conventions_exist
    warning_config = stub(fail_on_severity: 'warning', min_coverage: nil)
    convention_result = stub(
      offenses: [
        {
          severity: 'convention',
          type: 'line',
          name: 'Conv',
          message: 'msg',
          location: 'f.rb',
          location_line: 1
        }
      ]
    )
    agg = Yard::Lint::Results::Aggregate.new([convention_result], warning_config)
    assert_equal(0, agg.exit_code)
  end

  def test_exit_code_when_fail_on_severity_is_warning_returns_0_if_no_offenses
    warning_config = stub(fail_on_severity: 'warning', min_coverage: nil)
    agg = Yard::Lint::Results::Aggregate.new([], warning_config)
    assert_equal(0, agg.exit_code)
  end

  # exit_code tests with fail_on_severity = "convention"

  def test_exit_code_when_fail_on_severity_is_convention_returns_1_if_any_offenses_exist
    convention_config = stub(fail_on_severity: 'convention', min_coverage: nil)
    agg = Yard::Lint::Results::Aggregate.new([@result1, @result2, @result3], convention_config)
    assert_equal(1, agg.exit_code)
  end

  def test_exit_code_when_fail_on_severity_is_convention_returns_0_if_no_offenses
    convention_config = stub(fail_on_severity: 'convention', min_coverage: nil)
    agg = Yard::Lint::Results::Aggregate.new([], convention_config)
    assert_equal(0, agg.exit_code)
  end

  # exit_code tests with fail_on_severity = "unknown"

  def test_exit_code_when_fail_on_severity_is_unknown_returns_0
    unknown_config = stub(fail_on_severity: 'unknown', min_coverage: nil)
    agg = Yard::Lint::Results::Aggregate.new([@result1, @result2, @result3], unknown_config)
    assert_equal(0, agg.exit_code)
  end
end

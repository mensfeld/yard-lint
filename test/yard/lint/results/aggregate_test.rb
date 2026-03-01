# frozen_string_literal: true

require 'test_helper'


describe 'Yard::Lint::Results::Aggregate' do
  attr_reader :result1, :result2, :result3, :config, :aggregate


  before do
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

  it 'initialize accepts array of results' do
    Yard::Lint::Results::Aggregate.new([@result1, @result2], @config)
  end

  it 'initialize handles single result' do
    agg = Yard::Lint::Results::Aggregate.new(@result1, @config)
    assert_equal(2, agg.offenses.size)
  end

  it 'initialize handles nil results' do
    agg = Yard::Lint::Results::Aggregate.new(nil, @config)
    assert_equal([], agg.offenses)
  end

  it 'initialize handles empty array' do
    agg = Yard::Lint::Results::Aggregate.new([], @config)
    assert_equal([], agg.offenses)
  end

  it 'initialize stores config' do
    assert_equal(@config, @aggregate.config)
  end

  it 'offenses flattens all offenses from all results' do
    assert_kind_of(Array, @aggregate.offenses)
    assert_equal(3, @aggregate.offenses.size)
  end

  it 'offenses preserves offense structure' do
    offense = @aggregate.offenses.first
    assert(offense.key?(:severity))
    assert(offense.key?(:type))
    assert(offense.key?(:name))
    assert(offense.key?(:message))
    assert(offense.key?(:location))
    assert(offense.key?(:location_line))
  end

  it 'offenses includes offenses from all results' do
    names = @aggregate.offenses.map { |o| o[:name] }.sort
    assert_equal(%w[Convention1 Error1 Warning1], names)
  end

  it 'count returns total number of offenses' do
    assert_equal(3, @aggregate.count)
  end

  it 'count returns 0 when no offenses' do
    empty_aggregate = Yard::Lint::Results::Aggregate.new([@result3], @config)
    assert_equal(0, empty_aggregate.count)
  end

  it 'clean returns false when offenses exist' do
    assert_equal(false, @aggregate.clean?)
  end

  it 'clean returns true when no offenses' do
    empty_aggregate = Yard::Lint::Results::Aggregate.new([@result3], @config)
    assert_equal(true, empty_aggregate.clean?)
  end

  it 'statistics counts offenses by severity' do
    stats = @aggregate.statistics
    assert_kind_of(Hash, stats)
    assert_equal(1, stats[:error])
    assert_equal(1, stats[:warning])
    assert_equal(1, stats[:convention])
  end

  it 'statistics initializes all severity counts to 0' do
    empty_aggregate = Yard::Lint::Results::Aggregate.new([], @config)
    stats = empty_aggregate.statistics
    assert_equal(0, stats[:error])
    assert_equal(0, stats[:warning])
    assert_equal(0, stats[:convention])
  end

  it 'statistics handles multiple offenses of same severity' do
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

  it 'exit code when fail on severity is error returns 1 if errors exist' do
    error_config = stub(fail_on_severity: 'error', min_coverage: nil)
    agg = Yard::Lint::Results::Aggregate.new([@result1, @result2, @result3], error_config)
    assert_equal(1, agg.exit_code)
  end

  it 'exit code when fail on severity is error returns 0 if only warnings exist' do
    error_config = stub(fail_on_severity: 'error', min_coverage: nil)
    agg = Yard::Lint::Results::Aggregate.new([@result2], error_config)
    assert_equal(0, agg.exit_code)
  end

  it 'exit code when fail on severity is error returns 0 if no offenses' do
    error_config = stub(fail_on_severity: 'error', min_coverage: nil)
    agg = Yard::Lint::Results::Aggregate.new([], error_config)
    assert_equal(0, agg.exit_code)
  end

  # exit_code tests with fail_on_severity = "warning"

  it 'exit code when fail on severity is warning returns 1 if errors exist' do
    warning_config = stub(fail_on_severity: 'warning', min_coverage: nil)
    agg = Yard::Lint::Results::Aggregate.new([@result1, @result2, @result3], warning_config)
    assert_equal(1, agg.exit_code)
  end

  it 'exit code when fail on severity is warning returns 1 if warnings exist' do
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

  it 'exit code when fail on severity is warning returns 0 if only conventions exist' do
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

  it 'exit code when fail on severity is warning returns 0 if no offenses' do
    warning_config = stub(fail_on_severity: 'warning', min_coverage: nil)
    agg = Yard::Lint::Results::Aggregate.new([], warning_config)
    assert_equal(0, agg.exit_code)
  end

  # exit_code tests with fail_on_severity = "convention"

  it 'exit code when fail on severity is convention returns 1 if any offenses exist' do
    convention_config = stub(fail_on_severity: 'convention', min_coverage: nil)
    agg = Yard::Lint::Results::Aggregate.new([@result1, @result2, @result3], convention_config)
    assert_equal(1, agg.exit_code)
  end

  it 'exit code when fail on severity is convention returns 0 if no offenses' do
    convention_config = stub(fail_on_severity: 'convention', min_coverage: nil)
    agg = Yard::Lint::Results::Aggregate.new([], convention_config)
    assert_equal(0, agg.exit_code)
  end

  # exit_code tests with fail_on_severity = "unknown"

  it 'exit code when fail on severity is unknown returns 0' do
    unknown_config = stub(fail_on_severity: 'unknown', min_coverage: nil)
    agg = Yard::Lint::Results::Aggregate.new([@result1, @result2, @result3], unknown_config)
    assert_equal(0, agg.exit_code)
  end
end

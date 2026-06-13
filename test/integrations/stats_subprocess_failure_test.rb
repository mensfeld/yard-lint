# frozen_string_literal: true

require 'open3'

# Proves that documentation coverage is reported as unknown (not 100%) when the
# YARD stats subprocess fails, and that a MinCoverage gate then fails safe
# instead of silently passing.
describe 'Stats subprocess failure' do
  it 'returns nil coverage instead of 100% when the yard subprocess fails' do
    config = test_config { |c| c.min_coverage = 80 }
    fixture = File.expand_path('../fixtures/never_severity.rb', __dir__)
    calculator = Yard::Lint::StatsCalculator.new(config, [fixture])

    # Simulate the yard stats subprocess failing.
    Open3.stubs(:capture3).returns(['', 'boom', stub(exitstatus: 1)])

    assert_nil(calculator.calculate, 'failed subprocess should yield unknown coverage, not 100%')
  end

  it 'fails the build when MinCoverage is required but coverage is unknown' do
    config = test_config { |c| c.min_coverage = 80 }
    result = Yard::Lint::Results::Aggregate.new([], config, ['some_file.rb'])
    result.stubs(:documentation_coverage).returns(nil)

    assert_equal(1, result.exit_code, 'a required-but-unknown coverage must not pass')
  end
end

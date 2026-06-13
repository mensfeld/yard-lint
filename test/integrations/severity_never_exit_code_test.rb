# frozen_string_literal: true

# Proves that offenses whose severity is "never" do not cause a non-zero exit
# code, even under FailOnSeverity: convention. The convention branch used
# offenses.any?, counting never-severity offenses that #statistics excludes.
describe 'Severity never exit code' do
  it 'does not fail the build on a never-severity offense under convention' do
    config = test_config do |c|
      c.set_validator_config('Documentation/UndocumentedObjects', 'Severity', 'never')
      c.fail_on_severity = 'convention'
    end

    fixture_path = File.expand_path('../fixtures/never_severity.rb', __dir__)
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    # The undocumented class is still reported...
    assert(result.offenses.any? { |o| o[:severity] == 'never' }, 'expected a never-severity offense')
    # ...but it must not fail the build.
    assert_equal(0, result.exit_code, 'a never-severity offense caused a non-zero exit code')
  end
end

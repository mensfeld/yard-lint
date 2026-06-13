# frozen_string_literal: true

# Proves that an unnamed @example does not shift the parser fields in
# Tags/ExampleSyntax. YARD returns "" (not nil) for an unnamed example, so the
# `example.name || "Example N"` fallback never fired; the empty name line was
# dropped by the parser's reject(&:empty?), shifting the syntax-error message
# into the example-name slot.
describe 'Unnamed example syntax error' do
  it 'reports a well-formed offense for an unnamed example' do
    fixture_path = File.expand_path('../fixtures/unnamed_example.rb', __dir__)
    result = Yard::Lint.run(path: fixture_path, config: test_config, progress: false)

    offense = result.offenses.find { |o| o[:name] == 'ExampleSyntax' }
    refute_nil(offense)
    # The fallback name appears, and the syntax error detail follows it.
    assert_includes(offense[:message], "'Example 1'")
    assert_match(/'Example 1':.*syntax error/, offense[:message])
  end
end

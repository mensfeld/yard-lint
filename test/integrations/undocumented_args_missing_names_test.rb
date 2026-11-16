# frozen_string_literal: true

# Proves that Documentation/UndocumentedMethodArguments names the missing
# arguments when it matches them by name, and keeps the generic message in
# count-only mode.
describe 'Documentation/UndocumentedMethodArguments missing argument names' do
  def fixture_path
    File.expand_path('fixtures/undocumented_args_missing_names.rb', __dir__)
  end

  def offenses(options = {})
    config = test_config do |c|
      c.set_validator_config('Documentation/UndocumentedMethodArguments', 'Enabled', true)
      options.each { |k, v| c.set_validator_config('Documentation/UndocumentedMethodArguments', k, v) }
    end
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
    result.offenses
          .select { |o| o[:name] == 'UndocumentedMethodArgument' }
          .to_h { |o| [o[:method_name], o] }
  end

  it 'names a misnamed @param argument' do
    assert_equal('The `greet` method has no @param for: name', offenses['greet'][:message])
  end

  it 'names every argument of an undocumented method' do
    assert_equal('The `undocumented` method has no @param for: a, b', offenses['undocumented'][:message])
  end

  it 'names a keyword argument without its colon' do
    assert_equal('The `keyword_missing` method has no @param for: limit', offenses['keyword_missing'][:message])
  end

  it 'names the argument of an operator method whose name is the separator' do
    assert_equal('The `|` method has no @param for: other', offenses['|'][:message])
  end

  it 'names a destructured argument as one argument' do
    assert_equal('The `destructured` method has no @param for: (a, b), c', offenses['destructured'][:message])
  end

  it 'names a destructured argument that spans lines on one line' do
    assert_equal(
      'The `destructured_multiline` method has no @param for: (a, b)',
      offenses['destructured_multiline'][:message]
    )
  end

  it 'names a repeated argument once' do
    assert_equal('The `repeated` method has no @param for: _, x', offenses['repeated'][:message])
  end

  it 'identifies the offending method so SARIF fingerprints do not depend on the message' do
    assert_equal('UndocumentedArgsMissingNames#greet', offenses['greet'][:element])
  end

  it 'keeps the generic message in count-only mode' do
    found = offenses('CheckParameterNames' => false)

    refute_includes(found.keys, 'greet')
    assert_equal(
      'The `undocumented` method is missing documentation for some of the arguments.',
      found['undocumented'][:message]
    )
    assert_equal(
      'The `keyword_missing` method is missing documentation for some of the arguments.',
      found['keyword_missing'][:message]
    )
  end
end

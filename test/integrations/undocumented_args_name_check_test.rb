# frozen_string_literal: true

# BUG-041: Documentation/UndocumentedMethodArguments only compared the @param
# tag *count* to the parameter count, so a misnamed @param satisfied it, and it
# also re-reported methods that have no documentation at all (already covered by
# UndocumentedObjects). Fixed by:
#   - CheckParameterNames (default true): match each parameter to a @param tag by
#     name; set false to fall back to the lenient count-only comparison.
#   - SkipFullyUndocumented (default false, opt-in): defer no-docstring methods to
#     UndocumentedObjects.
describe 'Documentation/UndocumentedMethodArguments BUG-041 options' do
  # A method (not a constant): a constant assigned inside a `describe` block
  # leaks to the top-level lexical scope, colliding with other test files.
  def fixture_path
    File.expand_path('fixtures/undocumented_args_name_check.rb', __dir__)
  end

  def flagged_methods(options = {})
    config = test_config do |c|
      c.set_validator_config('Documentation/UndocumentedMethodArguments', 'Enabled', true)
      options.each { |k, v| c.set_validator_config('Documentation/UndocumentedMethodArguments', k, v) }
    end
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
    result.offenses
          .select { |o| o[:name] == 'UndocumentedMethodArgument' }
          .map { |o| o[:method_name] }
          .compact
          .sort
  end

  it 'flags a misnamed @param by default (name-based)' do
    methods = flagged_methods
    assert_includes(methods, 'misnamed_param', 'item is not documented despite a 1:1 count')
    assert_includes(methods, 'fully_undocumented')
    assert_includes(methods, 'partially_documented')
  end

  it 'does not flag fully or correctly documented methods by default' do
    methods = flagged_methods
    refute_includes(methods, 'all_documented')
    refute_includes(methods, 'keyword_documented', 'keyword param name: must match @param name')
  end

  it 'CheckParameterNames: false falls back to the lenient count-only check' do
    methods = flagged_methods('CheckParameterNames' => false)
    refute_includes(methods, 'misnamed_param', 'count-only mode accepts a misnamed @param')
    # Count mismatch is still caught even in count-only mode.
    assert_includes(methods, 'partially_documented')
    assert_includes(methods, 'fully_undocumented')
  end

  it 'SkipFullyUndocumented defers a no-docstring method to UndocumentedObjects' do
    methods = flagged_methods('SkipFullyUndocumented' => true)
    refute_includes(methods, 'fully_undocumented')
    # A partially-documented method still has a docstring, so it is still checked.
    assert_includes(methods, 'partially_documented')
  end

  it 'the two options compose' do
    methods = flagged_methods('CheckParameterNames' => true, 'SkipFullyUndocumented' => true)
    refute_includes(methods, 'fully_undocumented')
    assert_includes(methods, 'misnamed_param')
    assert_includes(methods, 'partially_documented')
  end
end

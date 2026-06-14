# frozen_string_literal: true

# BUG-041: Documentation/UndocumentedMethodArguments only compared the @param
# tag *count* to the parameter count, so a misnamed @param satisfied it, and it
# also re-reported methods that have no documentation at all (already covered by
# UndocumentedObjects). Two opt-in options (default off) address this:
#   - CheckParameterNames: match each parameter to a @param tag by name
#   - SkipFullyUndocumented: defer no-docstring methods to UndocumentedObjects
describe 'Documentation/UndocumentedMethodArguments BUG-041 options' do
  FIXTURE = File.expand_path('fixtures/undocumented_args_name_check.rb', __dir__)

  def flagged_methods(options = {})
    config = test_config do |c|
      c.set_validator_config('Documentation/UndocumentedMethodArguments', 'Enabled', true)
      options.each { |k, v| c.set_validator_config('Documentation/UndocumentedMethodArguments', k, v) }
    end
    result = Yard::Lint.run(path: FIXTURE, config: config, progress: false)
    result.offenses
          .select { |o| o[:name] == 'UndocumentedMethodArgument' }
          .map { |o| o[:method_name] }
          .compact
          .sort
  end

  it 'default (count-based) flags missing-count methods but not a misnamed @param' do
    methods = flagged_methods
    assert_includes(methods, 'fully_undocumented')
    assert_includes(methods, 'partially_documented')
    refute_includes(methods, 'misnamed_param', 'count check accepts a misnamed @param')
    refute_includes(methods, 'all_documented')
    refute_includes(methods, 'keyword_documented')
  end

  it 'CheckParameterNames flags a misnamed @param' do
    methods = flagged_methods('CheckParameterNames' => true)
    assert_includes(methods, 'misnamed_param', 'item is not documented despite a 1:1 count')
    assert_includes(methods, 'partially_documented')
  end

  it 'CheckParameterNames does not flag fully or correctly documented methods' do
    methods = flagged_methods('CheckParameterNames' => true)
    refute_includes(methods, 'all_documented')
    refute_includes(methods, 'keyword_documented', 'keyword param name: must match @param name')
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

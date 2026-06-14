# frozen_string_literal: true

# BUG-046: Tags/ExampleSyntax compiles every @example body as Ruby, so an irb /
# pry / shell transcript (or its `=>` output lines) is reported as a syntax
# error. The opt-in SkipNonRuby option (default false) skips @example blocks
# that are interactive console transcripts rather than runnable Ruby.
describe 'Tags/ExampleSyntax SkipNonRuby' do
  # A method (not a constant): a constant assigned inside a `describe` block
  # leaks to the top-level lexical scope, colliding with other test files.
  def fixture_path
    File.expand_path('fixtures/example_syntax_non_ruby.rb', __dir__)
  end

  def example_offenses(skip_non_ruby:)
    config = test_config do |c|
      c.set_validator_config('Tags/ExampleSyntax', 'Enabled', true)
      c.set_validator_config('Tags/ExampleSyntax', 'SkipNonRuby', skip_non_ruby)
    end
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
    result.offenses.select { |o| o[:name] == 'ExampleSyntax' }
  end

  def flagged_methods(offenses)
    offenses.map { |o| o[:message][/#(\w+)/, 1] }.compact.sort
  end

  it 'is off by default: console transcripts are still flagged' do
    methods = flagged_methods(example_offenses(skip_non_ruby: false))
    # All four transcript styles plus the genuinely broken example; not the
    # valid hash-rocket example.
    assert_includes(methods, 'irb_method')
    assert_includes(methods, 'irb_prompt_method')
    assert_includes(methods, 'pry_method')
    assert_includes(methods, 'shell_method')
    assert_includes(methods, 'broken_method')
    refute_includes(methods, 'hash_rocket_method')
  end

  it 'when enabled: skips irb, irb-prompt, pry, and shell transcripts' do
    methods = flagged_methods(example_offenses(skip_non_ruby: true))
    refute_includes(methods, 'irb_method')
    refute_includes(methods, 'irb_prompt_method')
    refute_includes(methods, 'pry_method')
    refute_includes(methods, 'shell_method')
  end

  it 'when enabled: still flags a genuine Ruby syntax error' do
    methods = flagged_methods(example_offenses(skip_non_ruby: true))
    assert_includes(methods, 'broken_method')
  end

  it 'when enabled: does not skip valid Ruby that uses a hash rocket' do
    methods = flagged_methods(example_offenses(skip_non_ruby: true))
    refute_includes(methods, 'hash_rocket_method')
  end
end

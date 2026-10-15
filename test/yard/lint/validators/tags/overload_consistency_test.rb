# frozen_string_literal: true

describe 'Yard::Lint::Validators::Tags::OverloadConsistency' do
  it 'has required sub modules and classes' do
    mod = Yard::Lint::Validators::Tags::OverloadConsistency
    assert_equal(true, mod.const_defined?(:Config))
    assert_equal(true, mod.const_defined?(:Validator))
    assert_equal(true, mod.const_defined?(:Parser))
    assert_equal(true, mod.const_defined?(:Result))
    assert_equal(true, mod.const_defined?(:MessagesBuilder))
  end

  it 'is discovered by the config loader' do
    assert_includes(Yard::Lint::ConfigLoader::ALL_VALIDATORS, 'Tags/OverloadConsistency')
  end

  it 'runs in process over all visibilities' do
    validator = Yard::Lint::Validators::Tags::OverloadConsistency::Validator
    assert_predicate(validator, :in_process?)
    assert_equal(:all, validator.in_process_visibility)
  end
end

describe 'Yard::Lint::Validators::Tags::OverloadConsistency::Config' do
  it 'id returns the validator identifier' do
    assert_equal(:overload_consistency, Yard::Lint::Validators::Tags::OverloadConsistency::Config.id)
  end

  it 'defaults to enabled with warning severity' do
    defaults = Yard::Lint::Validators::Tags::OverloadConsistency::Config.defaults
    assert_equal(true, defaults['Enabled'])
    assert_equal('warning', defaults['Severity'])
  end
end

describe 'Yard::Lint::Validators::Tags::OverloadConsistency::Parser' do
  attr_reader :parser

  before do
    @parser = Yard::Lint::Validators::Tags::OverloadConsistency::Parser.new
  end

  it 'parses two-line violations' do
    output = <<~OUTPUT
      lib/example.rb:10: Example#fetch
      unknown_param|name|fetch(key)
      lib/example.rb:10: Example#fetch
      missing_return||fetch(key, default)
    OUTPUT

    assert_equal(
      [
        {
          location: 'lib/example.rb',
          line: 10,
          object_name: 'Example#fetch',
          kind: 'unknown_param',
          param: 'name',
          signature: 'fetch(key)'
        },
        {
          location: 'lib/example.rb',
          line: 10,
          object_name: 'Example#fetch',
          kind: 'missing_return',
          param: '',
          signature: 'fetch(key, default)'
        }
      ],
      parser.call(output)
    )
  end

  it 'keeps a pipe inside the signature' do
    output = "lib/example.rb:3: Example#|\nundocumented_param|other||(other)\n"

    assert_equal('|(other)', parser.call(output).first[:signature])
  end

  it 'returns an empty array for empty output' do
    assert_equal([], parser.call(''))
    assert_equal([], parser.call(nil))
  end

  it 'skips malformed entries' do
    assert_equal([], parser.call("not a location\nunknown_param|a|run(b)\n"))
    assert_equal([], parser.call("lib/example.rb:10: Example#run\nother|a|run(b)\n"))
    assert_equal([], parser.call("lib/example.rb:10: Example#run\nunknown_param|a\n"))
  end
end

describe 'Yard::Lint::Validators::Tags::OverloadConsistency::MessagesBuilder' do
  # @param offense [Hash] offense details
  # @return [String] built message
  def message_for(offense)
    Yard::Lint::Validators::Tags::OverloadConsistency::MessagesBuilder.call(offense)
  end

  it 'names the unknown @param' do
    assert_equal(
      "Overload 'fetch(key)' documents @param 'name', which is not in its signature",
      message_for(kind: 'unknown_param', param: 'name', signature: 'fetch(key)')
    )
  end

  it 'names the undocumented parameter' do
    assert_equal(
      "Overload 'fetch(key)' has no @param for 'key'",
      message_for(kind: 'undocumented_param', param: 'key', signature: 'fetch(key)')
    )
  end

  it 'reports the missing @return' do
    assert_equal(
      "Overload 'fetch(key)' has no @return, while other overloads of this method have one",
      message_for(kind: 'missing_return', param: '', signature: 'fetch(key)')
    )
  end
end

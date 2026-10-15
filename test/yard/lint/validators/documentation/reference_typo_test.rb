# frozen_string_literal: true

describe 'Yard::Lint::Validators::Documentation::ReferenceTypo' do
  it 'has required sub modules and classes' do
    mod = Yard::Lint::Validators::Documentation::ReferenceTypo
    assert_equal(true, mod.const_defined?(:Config))
    assert_equal(true, mod.const_defined?(:Validator))
    assert_equal(true, mod.const_defined?(:Parser))
    assert_equal(true, mod.const_defined?(:Result))
    assert_equal(true, mod.const_defined?(:MessagesBuilder))
  end

  it 'is discovered by the config loader' do
    assert_includes(Yard::Lint::ConfigLoader::ALL_VALIDATORS, 'Documentation/ReferenceTypo')
  end

  it 'runs in process over all visibilities' do
    validator = Yard::Lint::Validators::Documentation::ReferenceTypo::Validator
    assert_predicate(validator, :in_process?)
    assert_equal(:all, validator.in_process_visibility)
  end
end

describe 'Yard::Lint::Validators::Documentation::ReferenceTypo::Config' do
  it 'id returns the validator identifier' do
    assert_equal(:reference_typo, Yard::Lint::Validators::Documentation::ReferenceTypo::Config.id)
  end

  it 'defaults to enabled with warning severity' do
    defaults = Yard::Lint::Validators::Documentation::ReferenceTypo::Config.defaults
    assert_equal(true, defaults['Enabled'])
    assert_equal('warning', defaults['Severity'])
  end
end

describe 'Yard::Lint::Validators::Documentation::ReferenceTypo::Parser' do
  attr_reader :parser

  before do
    @parser = Yard::Lint::Validators::Documentation::ReferenceTypo::Parser.new
  end

  it 'parses two-line violations' do
    output = <<~OUTPUT
      lib/example.rb:10: Example#call
      Example#prase|Example#parse
    OUTPUT

    assert_equal(
      [
        {
          location: 'lib/example.rb',
          line: 10,
          object_name: 'Example#call',
          reference: 'Example#prase',
          suggestion: 'Example#parse'
        }
      ],
      parser.call(output)
    )
  end

  it 'returns an empty array for empty output' do
    assert_equal([], parser.call(''))
    assert_equal([], parser.call(nil))
  end

  it 'skips malformed entries' do
    assert_equal([], parser.call("not a location\nfoo|bar\n"))
    assert_equal([], parser.call("lib/example.rb:10: Example#call\nno_suggestion\n"))
  end
end

describe 'Yard::Lint::Validators::Documentation::ReferenceTypo::MessagesBuilder' do
  it 'names the reference and the suggestion' do
    message = Yard::Lint::Validators::Documentation::ReferenceTypo::MessagesBuilder.call(
      reference: '#prase', suggestion: '#parse'
    )

    assert_equal("Reference '#prase' does not resolve (did you mean '#parse'?)", message)
  end
end

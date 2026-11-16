# frozen_string_literal: true

describe 'Yard::Lint::Validators::Documentation::UndocumentedMethodArguments::Parser' do
  attr_reader :parser

  before do
    @parser = Yard::Lint::Validators::Documentation::UndocumentedMethodArguments::Parser.new
  end

  it 'initialize inherits from parser base class' do
    assert_kind_of(Yard::Lint::Parsers::Base, parser)
  end

  it 'call parses input and returns array' do
    result = parser.call('')
    assert_kind_of(Array, result)
  end

  it 'call handles empty input' do
    result = parser.call('')
  end

  it 'call parses the missing argument names' do
    result = parser.call("lib/foo.rb:10: Foo::Bar#process\tname,options\n")

    assert_equal(
      [
        {
          location: 'lib/foo.rb',
          method_name: 'process',
          line: 10,
          class_name: 'Foo::Bar',
          element: 'Foo::Bar#process',
          missing_params: %w[name options]
        }
      ],
      result
    )
  end

  it 'call returns no missing names in count-only output' do
    result = parser.call("lib/foo.rb:10: Foo#process\t\n")

    assert_equal([], result.first[:missing_params])
    assert_equal('process', result.first[:method_name])
  end

  it 'call parses a top-level method title' do
    result = parser.call("lib/foo.rb:3: #greet\tname\n")

    assert_equal('greet', result.first[:method_name])
    assert_equal('#greet', result.first[:element])
    assert_equal(%w[name], result.first[:missing_params])
  end

  it 'call parses an operator method title' do
    result = parser.call("lib/foo.rb:3: Foo#|\tother\n")

    assert_equal('|', result.first[:method_name])
    assert_equal('Foo#|', result.first[:element])
    assert_equal(%w[other], result.first[:missing_params])
  end

  it 'call parses a plain location line as other validators send it' do
    result = parser.call("lib/foo.rb:10: Foo#process\n")

    assert_equal(
      [{ location: 'lib/foo.rb', method_name: 'process', line: 10, class_name: 'Foo' }],
      result
    )
  end
end

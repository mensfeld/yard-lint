# frozen_string_literal: true

describe 'Yard::Lint::Validators::Documentation::UndocumentedBooleanMethods::Parser' do
  attr_reader :parser

  before do
    @parser = Yard::Lint::Validators::Documentation::UndocumentedBooleanMethods::Parser.new
  end

  it 'initialize inherits from parser base class' do
    assert_kind_of(Yard::Lint::Parsers::Base, parser)
  end

  it 'call parses input and returns array' do
    result = parser.call('')
    assert_kind_of(Array, result)
  end

  it 'call handles empty input' do
    assert_equal([], parser.call(''))
  end

  it 'call parses file, line and an instance method' do
    result = parser.call("lib/user.rb:12: App::User#active?\n")

    assert_equal(
      [{ location: 'lib/user.rb', line: 12, element: 'App::User#active?', method_name: 'active?' }],
      result
    )
  end

  it 'call keeps the dot of a class method' do
    result = parser.call('lib/user.rb:3: App::User.enabled?')

    assert_equal('App::User.enabled?', result.first[:element])
    assert_equal('enabled?', result.first[:method_name])
    assert_equal(3, result.first[:line])
  end

  it 'call skips lines without a location' do
    assert_equal([], parser.call('App::User#active?'))
  end
end


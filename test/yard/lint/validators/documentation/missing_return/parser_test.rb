# frozen_string_literal: true

require 'test_helper'


describe 'Yard::Lint::Validators::Documentation::MissingReturn::Parser' do
  attr_reader :parser


  before do
    @parser = Yard::Lint::Validators::Documentation::MissingReturn::Parser.new
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
    assert_equal([], result)
  end

  it 'call parses valid offense line' do
    input = 'lib/example.rb:10: Calculator#add|2'
    result = parser.call(input)

    assert_equal([{
      location: 'lib/example.rb',
      line: 10,
      element: 'Calculator#add'
    }], result)
  end

  it 'call parses multiple offense lines' do
    input = <<~OUTPUT
      lib/example.rb:10: Calculator#add|2
      lib/example.rb:20: Calculator#multiply|2
    OUTPUT

    result = parser.call(input)
    assert_equal(2, result.size)
    assert_equal('Calculator#add', result[0][:element])
    assert_equal('Calculator#multiply', result[1][:element])
  end

  it 'call parses class methods' do
    input = 'lib/example.rb:5: Calculator.new|1'
    result = parser.call(input)

    assert_equal([{
      location: 'lib/example.rb',
      line: 5,
      element: 'Calculator.new'
    }], result)
  end

  it 'call handles methods with zero arity' do
    input = 'lib/example.rb:15: Calculator#current_value|0'
    result = parser.call(input)

    assert_equal([{
      location: 'lib/example.rb',
      line: 15,
      element: 'Calculator#current_value'
    }], result)
  end

  it 'call skips invalid lines' do
    input = <<~OUTPUT
      lib/example.rb:10: Calculator#add|2
      Invalid line without proper format
      lib/example.rb:20: Calculator#multiply|2
    OUTPUT

    result = parser.call(input)
    assert_equal(2, result.size)
  end

  it 'call handles lines with whitespace' do
    input = "  lib/example.rb:10: Calculator#add|2  \n\n"
    result = parser.call(input)

    assert_equal(1, result.size)
  end

  it 'call with config parameter accepts config keyword argument' do
    config = Yard::Lint::Config.new
    parser.call('', config: config)
  end

  it 'call with config parameter works without config parameter backwards compatibility' do
    parser.call('')
  end

  it 'call with simple name exclusion excludes methods matching simple name' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/MissingReturn', 'ExcludedMethods', ['initialize'])
    end

    input = 'lib/example.rb:5: Example#initialize|1'
    result = parser.call(input, config: config)

    assert_empty(result)
  end

  it 'call with simple name exclusion does not exclude methods with different names' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/MissingReturn', 'ExcludedMethods', ['initialize'])
    end

    input = 'lib/example.rb:10: Example#calculate|0'
    result = parser.call(input, config: config)

    assert_equal(1, result.size)
  end

  it 'call with simple name exclusion matches simple names with any arity' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/MissingReturn', 'ExcludedMethods', ['initialize'])
    end

    input = <<~OUTPUT
      lib/example.rb:5: Example#initialize|0
      lib/example.rb:10: Example#initialize|1
      lib/example.rb:15: Example#initialize|2
    OUTPUT

    result = parser.call(input, config: config)
    assert_empty(result)
  end

  it 'call with regex pattern exclusion excludes methods matching regex pattern' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/MissingReturn', 'ExcludedMethods', ['/^_/'])
    end

    input = 'lib/example.rb:10: Example#_private_helper|0'
    result = parser.call(input, config: config)

    assert_empty(result)
  end

  it 'call with regex pattern exclusion does not exclude methods not matching pattern' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/MissingReturn', 'ExcludedMethods', ['/^_/'])
    end

    input = 'lib/example.rb:10: Example#public_method|0'
    result = parser.call(input, config: config)

    assert_equal(1, result.size)
  end

  it 'call with regex pattern exclusion handles multiple regex patterns' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/MissingReturn', 'ExcludedMethods', ['/^_/', '/^test_/'])
    end

    input = <<~OUTPUT
      lib/example.rb:5: Example#_helper|0
      lib/example.rb:10: Example#test_something|0
      lib/example.rb:15: Example#regular_method|0
    OUTPUT

    result = parser.call(input, config: config)
    assert_equal(1, result.size)
    assert_equal('Example#regular_method', result[0][:element])
  end

  it 'call with regex pattern exclusion handles invalid regex gracefully' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/MissingReturn', 'ExcludedMethods', ['/[invalid/'])
    end

    input = 'lib/example.rb:10: Example#method|0'
    result = parser.call(input, config: config)

    # Invalid regex should be skipped, method should not be excluded
    assert_equal(1, result.size)
  end

  it 'call with regex pattern exclusion rejects empty regex patterns' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/MissingReturn', 'ExcludedMethods', ['//'])
    end

    input = 'lib/example.rb:10: Example#method|0'
    result = parser.call(input, config: config)

    # Empty regex would match everything, so it should be rejected
    assert_equal(1, result.size)
  end

  it 'call with arity pattern exclusion excludes methods matching name and arity' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/MissingReturn', 'ExcludedMethods', ['fetch/1'])
    end

    input = 'lib/example.rb:10: Cache#fetch|1'
    result = parser.call(input, config: config)

    assert_empty(result)
  end

  it 'call with arity pattern exclusion does not exclude methods with same name but different arity' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/MissingReturn', 'ExcludedMethods', ['fetch/1'])
    end

    input = 'lib/example.rb:10: Cache#fetch|2'
    result = parser.call(input, config: config)

    assert_equal(1, result.size)
  end

  it 'call with arity pattern exclusion does not exclude methods with different name but same arity' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/MissingReturn', 'ExcludedMethods', ['fetch/1'])
    end

    input = 'lib/example.rb:10: Cache#get|1'
    result = parser.call(input, config: config)

    assert_equal(1, result.size)
  end

  it 'call with arity pattern exclusion handles zero arity patterns' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/MissingReturn', 'ExcludedMethods', ['initialize/0'])
    end

    input = <<~OUTPUT
      lib/example.rb:5: Example#initialize|0
      lib/example.rb:10: Example#initialize|1
    OUTPUT

    result = parser.call(input, config: config)
    assert_equal(1, result.size)
    assert_equal(10, result[0][:line])
  end

  it 'call with mixed exclusion patterns applies all exclusion patterns' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/MissingReturn', 'ExcludedMethods', ['initialize', '/^_/', 'fetch/1'])
    end

    input = <<~OUTPUT
      lib/example.rb:5: Example#initialize|0
      lib/example.rb:10: Example#_helper|0
      lib/example.rb:15: Example#fetch|1
      lib/example.rb:20: Example#fetch|2
      lib/example.rb:25: Example#calculate|2
    OUTPUT

    result = parser.call(input, config: config)

    # Should exclude initialize, _helper, fetch/1
    # Should keep fetch/2 and calculate
    assert_equal(2, result.size)
    assert_equal('Example#fetch', result[0][:element])
    assert_equal(20, result[0][:line])
    assert_equal('Example#calculate', result[1][:element])
  end

  it 'call with edge cases handles nil excluded methods' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/MissingReturn', 'ExcludedMethods', nil)
    end

    input = 'lib/example.rb:10: Example#method|0'
    result = parser.call(input, config: config)

    assert_equal(1, result.size)
  end

  it 'call with edge cases handles empty excluded methods array' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/MissingReturn', 'ExcludedMethods', [])
    end

    input = 'lib/example.rb:10: Example#method|0'
    result = parser.call(input, config: config)

    assert_equal(1, result.size)
  end

  it 'call with edge cases sanitizes patterns with whitespace' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/MissingReturn', 'ExcludedMethods', ['  initialize  ', '', nil])
    end

    input = <<~OUTPUT
      lib/example.rb:5: Example#initialize|0
      lib/example.rb:10: Example#method|0
    OUTPUT

    result = parser.call(input, config: config)

    # Should exclude initialize (after trimming), method should pass
    assert_equal(1, result.size)
    assert_equal('Example#method', result[0][:element])
  end

  it 'call with edge cases handles class methods with namespaces' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/MissingReturn', 'ExcludedMethods', ['new'])
    end

    input = 'lib/example.rb:5: Foo::Bar::Baz.new|0'
    result = parser.call(input, config: config)

    assert_empty(result)
  end
end

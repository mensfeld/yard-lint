# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsDocumentationMissingReturnParserTest < Minitest::Test
  attr_reader :parser

  def setup
    @parser = Yard::Lint::Validators::Documentation::MissingReturn::Parser.new
  end

  def test_initialize_inherits_from_parser_base_class
    assert_kind_of(Yard::Lint::Parsers::Base, parser)
  end

  def test_call_parses_input_and_returns_array
    result = parser.call('')
    assert_kind_of(Array, result)
  end

  def test_call_handles_empty_input
    result = parser.call('')
    assert_equal([], result)
  end

  def test_call_parses_valid_offense_line
    input = 'lib/example.rb:10: Calculator#add|2'
    result = parser.call(input)

    assert_equal([{
      location: 'lib/example.rb',
      line: 10,
      element: 'Calculator#add'
    }], result)
  end

  def test_call_parses_multiple_offense_lines
    input = <<~OUTPUT
      lib/example.rb:10: Calculator#add|2
      lib/example.rb:20: Calculator#multiply|2
    OUTPUT

    result = parser.call(input)
    assert_equal(2, result.size)
    assert_equal('Calculator#add', result[0][:element])
    assert_equal('Calculator#multiply', result[1][:element])
  end

  def test_call_parses_class_methods
    input = 'lib/example.rb:5: Calculator.new|1'
    result = parser.call(input)

    assert_equal([{
      location: 'lib/example.rb',
      line: 5,
      element: 'Calculator.new'
    }], result)
  end

  def test_call_handles_methods_with_zero_arity
    input = 'lib/example.rb:15: Calculator#current_value|0'
    result = parser.call(input)

    assert_equal([{
      location: 'lib/example.rb',
      line: 15,
      element: 'Calculator#current_value'
    }], result)
  end

  def test_call_skips_invalid_lines
    input = <<~OUTPUT
      lib/example.rb:10: Calculator#add|2
      Invalid line without proper format
      lib/example.rb:20: Calculator#multiply|2
    OUTPUT

    result = parser.call(input)
    assert_equal(2, result.size)
  end

  def test_call_handles_lines_with_whitespace
    input = "  lib/example.rb:10: Calculator#add|2  \n\n"
    result = parser.call(input)

    assert_equal(1, result.size)
  end

  def test_call_with_config_parameter_accepts_config_keyword_argument
    config = Yard::Lint::Config.new
    parser.call('', config: config)
  end

  def test_call_with_config_parameter_works_without_config_parameter_backwards_compatibility
    parser.call('')
  end

  def test_call_with_simple_name_exclusion_excludes_methods_matching_simple_name
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/MissingReturn', 'ExcludedMethods', ['initialize'])
    end

    input = 'lib/example.rb:5: Example#initialize|1'
    result = parser.call(input, config: config)

    assert_empty(result)
  end

  def test_call_with_simple_name_exclusion_does_not_exclude_methods_with_different_names
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/MissingReturn', 'ExcludedMethods', ['initialize'])
    end

    input = 'lib/example.rb:10: Example#calculate|0'
    result = parser.call(input, config: config)

    assert_equal(1, result.size)
  end

  def test_call_with_simple_name_exclusion_matches_simple_names_with_any_arity
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/MissingReturn', 'ExcludedMethods', ['initialize'])
    end

    input = <<~OUTPUT
      lib/example.rb:5: Example#initialize|0
      lib/example.rb:10: Example#initialize|1
      lib/example.rb:15: Example#initialize|2
    OUTPUT

    result = parser.call(input, config: config)
    assert_empty(result)
  end

  def test_call_with_regex_pattern_exclusion_excludes_methods_matching_regex_pattern
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/MissingReturn', 'ExcludedMethods', ['/^_/'])
    end

    input = 'lib/example.rb:10: Example#_private_helper|0'
    result = parser.call(input, config: config)

    assert_empty(result)
  end

  def test_call_with_regex_pattern_exclusion_does_not_exclude_methods_not_matching_pattern
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/MissingReturn', 'ExcludedMethods', ['/^_/'])
    end

    input = 'lib/example.rb:10: Example#public_method|0'
    result = parser.call(input, config: config)

    assert_equal(1, result.size)
  end

  def test_call_with_regex_pattern_exclusion_handles_multiple_regex_patterns
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/MissingReturn', 'ExcludedMethods', ['/^_/', '/^test_/'])
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

  def test_call_with_regex_pattern_exclusion_handles_invalid_regex_gracefully
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/MissingReturn', 'ExcludedMethods', ['/[invalid/'])
    end

    input = 'lib/example.rb:10: Example#method|0'
    result = parser.call(input, config: config)

    # Invalid regex should be skipped, method should not be excluded
    assert_equal(1, result.size)
  end

  def test_call_with_regex_pattern_exclusion_rejects_empty_regex_patterns
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/MissingReturn', 'ExcludedMethods', ['//'])
    end

    input = 'lib/example.rb:10: Example#method|0'
    result = parser.call(input, config: config)

    # Empty regex would match everything, so it should be rejected
    assert_equal(1, result.size)
  end

  def test_call_with_arity_pattern_exclusion_excludes_methods_matching_name_and_arity
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/MissingReturn', 'ExcludedMethods', ['fetch/1'])
    end

    input = 'lib/example.rb:10: Cache#fetch|1'
    result = parser.call(input, config: config)

    assert_empty(result)
  end

  def test_call_with_arity_pattern_exclusion_does_not_exclude_methods_with_same_name_but_different_arity
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/MissingReturn', 'ExcludedMethods', ['fetch/1'])
    end

    input = 'lib/example.rb:10: Cache#fetch|2'
    result = parser.call(input, config: config)

    assert_equal(1, result.size)
  end

  def test_call_with_arity_pattern_exclusion_does_not_exclude_methods_with_different_name_but_same_arity
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/MissingReturn', 'ExcludedMethods', ['fetch/1'])
    end

    input = 'lib/example.rb:10: Cache#get|1'
    result = parser.call(input, config: config)

    assert_equal(1, result.size)
  end

  def test_call_with_arity_pattern_exclusion_handles_zero_arity_patterns
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/MissingReturn', 'ExcludedMethods', ['initialize/0'])
    end

    input = <<~OUTPUT
      lib/example.rb:5: Example#initialize|0
      lib/example.rb:10: Example#initialize|1
    OUTPUT

    result = parser.call(input, config: config)
    assert_equal(1, result.size)
    assert_equal(10, result[0][:line])
  end

  def test_call_with_mixed_exclusion_patterns_applies_all_exclusion_patterns
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/MissingReturn', 'ExcludedMethods', ['initialize', '/^_/', 'fetch/1'])
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

  def test_call_with_edge_cases_handles_nil_excluded_methods
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/MissingReturn', 'ExcludedMethods', nil)
    end

    input = 'lib/example.rb:10: Example#method|0'
    result = parser.call(input, config: config)

    assert_equal(1, result.size)
  end

  def test_call_with_edge_cases_handles_empty_excluded_methods_array
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/MissingReturn', 'ExcludedMethods', [])
    end

    input = 'lib/example.rb:10: Example#method|0'
    result = parser.call(input, config: config)

    assert_equal(1, result.size)
  end

  def test_call_with_edge_cases_sanitizes_patterns_with_whitespace
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/MissingReturn', 'ExcludedMethods', ['  initialize  ', '', nil])
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

  def test_call_with_edge_cases_handles_class_methods_with_namespaces
    config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/MissingReturn', 'ExcludedMethods', ['new'])
    end

    input = 'lib/example.rb:5: Foo::Bar::Baz.new|0'
    result = parser.call(input, config: config)

    assert_empty(result)
  end
end

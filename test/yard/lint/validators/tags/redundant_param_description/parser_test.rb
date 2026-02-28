# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsRedundantParamDescriptionParserTest < Minitest::Test
  attr_reader :parser

  def setup
    @parser = Yard::Lint::Validators::Tags::RedundantParamDescription::Parser.new
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

  def test_call_handles_nil_input
    result = parser.call(nil)
    assert_equal([], result)
  end

  def test_call_parses_article_param_pattern_correctly
    output = <<~OUTPUT
      lib/example.rb:10: MyClass#method
      param|appointment|The appointment|Appointment|article_param|2
    OUTPUT

    result = parser.call(output)
    assert_equal(
      [
        {
          name: 'RedundantParamDescription',
          tag_name: 'param',
          param_name: 'appointment',
          description: 'The appointment',
          type_name: 'Appointment',
          pattern_type: 'article_param',
          word_count: 2,
          location: 'lib/example.rb',
          line: 10,
          object_name: 'MyClass#method'
        }
      ],
      result
    )
  end

  def test_call_parses_possessive_param_pattern_correctly
    output = <<~OUTPUT
      lib/example.rb:15: MyClass#process
      param|appointment|The event's appointment|Appointment|possessive_param|3
    OUTPUT

    result = parser.call(output)
    assert_equal(1, result.length)
    assert_equal('possessive_param', result[0][:pattern_type])
    assert_equal("The event's appointment", result[0][:description])
  end

  def test_call_parses_type_restatement_pattern_correctly
    output = <<~OUTPUT
      lib/example.rb:20: MyClass#execute
      param|user|User object|User|type_restatement|2
    OUTPUT

    result = parser.call(output)
    assert_equal(1, result.length)
    assert_equal('type_restatement', result[0][:pattern_type])
    assert_equal('User object', result[0][:description])
  end

  def test_call_parses_param_to_verb_pattern_correctly
    output = <<~OUTPUT
      lib/example.rb:25: MyClass#run
      param|payments|Payments to count|Array|param_to_verb|3
    OUTPUT

    result = parser.call(output)
    assert_equal(1, result.length)
    assert_equal('param_to_verb', result[0][:pattern_type])
  end

  def test_call_parses_id_pattern_correctly
    output = <<~OUTPUT
      lib/example.rb:30: MyClass#find
      param|treatment_id|ID of the treatment|String|id_pattern|4
    OUTPUT

    result = parser.call(output)
    assert_equal(1, result.length)
    assert_equal('id_pattern', result[0][:pattern_type])
  end

  def test_call_parses_directional_date_pattern_correctly
    output = <<~OUTPUT
      lib/example.rb:35: MyClass#filter
      param|from|from this date|Date|directional_date|3
    OUTPUT

    result = parser.call(output)
    assert_equal(1, result.length)
    assert_equal('directional_date', result[0][:pattern_type])
  end

  def test_call_parses_type_generic_pattern_correctly
    output = <<~OUTPUT
      lib/example.rb:40: MyClass#create
      param|payment|Payment object|Payment|type_generic|2
    OUTPUT

    result = parser.call(output)
    assert_equal(1, result.length)
    assert_equal('type_generic', result[0][:pattern_type])
  end

  def test_call_parses_article_param_phrase_pattern_correctly
    output = <<~OUTPUT
      lib/example.rb:45: MyClass#perform
      param|action|The action being performed|Symbol|article_param_phrase|4
    OUTPUT

    result = parser.call(output)
    assert_equal(1, result.length)
    assert_equal('article_param_phrase', result[0][:pattern_type])
    assert_equal('The action being performed', result[0][:description])
  end

  def test_call_parses_multiple_violations
    output = <<~OUTPUT
      lib/example.rb:10: MyClass#method1
      param|user|The user|User|article_param|2
      lib/example.rb:20: MyClass#method2
      param|data|The data|Hash|article_param|2
    OUTPUT

    result = parser.call(output)
    assert_equal(2, result.length)
    assert_equal('user', result[0][:param_name])
    assert_equal('data', result[1][:param_name])
  end

  def test_call_handles_violations_without_type_name
    output = <<~OUTPUT
      lib/example.rb:10: MyClass#method
      param|data|The data||article_param|2
    OUTPUT

    result = parser.call(output)
    assert_equal(1, result.length)
    assert_nil(result[0][:type_name])
  end

  def test_call_ignores_lines_that_do_not_match_location_pattern
    output = <<~OUTPUT
      random text
      lib/example.rb:10: MyClass#method
      param|user|The user|User|article_param|2
    OUTPUT

    result = parser.call(output)
    assert_equal(1, result.length)
    assert_equal('user', result[0][:param_name])
  end
end


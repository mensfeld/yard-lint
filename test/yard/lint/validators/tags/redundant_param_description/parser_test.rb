# frozen_string_literal: true

require 'test_helper'


describe 'Yard::Lint::Validators::Tags::RedundantParamDescription::Parser' do
  attr_reader :parser


  before do
    @parser = Yard::Lint::Validators::Tags::RedundantParamDescription::Parser.new
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

  it 'call handles nil input' do
    result = parser.call(nil)
    assert_equal([], result)
  end

  it 'call parses article param pattern correctly' do
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

  it 'call parses possessive param pattern correctly' do
    output = <<~OUTPUT
      lib/example.rb:15: MyClass#process
      param|appointment|The event's appointment|Appointment|possessive_param|3
    OUTPUT

    result = parser.call(output)
    assert_equal(1, result.length)
    assert_equal('possessive_param', result[0][:pattern_type])
    assert_equal("The event's appointment", result[0][:description])
  end

  it 'call parses type restatement pattern correctly' do
    output = <<~OUTPUT
      lib/example.rb:20: MyClass#execute
      param|user|User object|User|type_restatement|2
    OUTPUT

    result = parser.call(output)
    assert_equal(1, result.length)
    assert_equal('type_restatement', result[0][:pattern_type])
    assert_equal('User object', result[0][:description])
  end

  it 'call parses param to verb pattern correctly' do
    output = <<~OUTPUT
      lib/example.rb:25: MyClass#run
      param|payments|Payments to count|Array|param_to_verb|3
    OUTPUT

    result = parser.call(output)
    assert_equal(1, result.length)
    assert_equal('param_to_verb', result[0][:pattern_type])
  end

  it 'call parses id pattern correctly' do
    output = <<~OUTPUT
      lib/example.rb:30: MyClass#find
      param|treatment_id|ID of the treatment|String|id_pattern|4
    OUTPUT

    result = parser.call(output)
    assert_equal(1, result.length)
    assert_equal('id_pattern', result[0][:pattern_type])
  end

  it 'call parses directional date pattern correctly' do
    output = <<~OUTPUT
      lib/example.rb:35: MyClass#filter
      param|from|from this date|Date|directional_date|3
    OUTPUT

    result = parser.call(output)
    assert_equal(1, result.length)
    assert_equal('directional_date', result[0][:pattern_type])
  end

  it 'call parses type generic pattern correctly' do
    output = <<~OUTPUT
      lib/example.rb:40: MyClass#create
      param|payment|Payment object|Payment|type_generic|2
    OUTPUT

    result = parser.call(output)
    assert_equal(1, result.length)
    assert_equal('type_generic', result[0][:pattern_type])
  end

  it 'call parses article param phrase pattern correctly' do
    output = <<~OUTPUT
      lib/example.rb:45: MyClass#perform
      param|action|The action being performed|Symbol|article_param_phrase|4
    OUTPUT

    result = parser.call(output)
    assert_equal(1, result.length)
    assert_equal('article_param_phrase', result[0][:pattern_type])
    assert_equal('The action being performed', result[0][:description])
  end

  it 'call parses multiple violations' do
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

  it 'call handles violations without type name' do
    output = <<~OUTPUT
      lib/example.rb:10: MyClass#method
      param|data|The data||article_param|2
    OUTPUT

    result = parser.call(output)
    assert_equal(1, result.length)
    assert_nil(result[0][:type_name])
  end

  it 'call ignores lines that do not match location pattern' do
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


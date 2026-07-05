# frozen_string_literal: true

describe "Yard::Lint::Validators::Tags::TagSeparator::Parser" do
  attr_reader :parser

  before do
    @parser = Yard::Lint::Validators::Tags::TagSeparator::Parser.new
  end

  it "initialize inherits from parser base class" do
    assert_kind_of(Yard::Lint::Parsers::Base, parser)
  end

  it "call parses input and returns array" do
    result = parser.call("")

    assert_kind_of(Array, result)
  end

  it "call handles empty input" do
    result = parser.call("")

    assert_equal([], result)
  end

  it "call handles nil input" do
    result = parser.call(nil)

    assert_equal([], result)
  end

  it "call with valid entries filters out valid entries" do
    input = <<~OUTPUT
      lib/example.rb:10: Example#method
      valid
    OUTPUT

    result = parser.call(input)

    assert_empty(result)
  end

  it "call with offense entries parses offense entries" do
    input = <<~OUTPUT
      lib/example.rb:10: Example#method
      param->param
    OUTPUT

    result = parser.call(input)

    assert_equal(1, result.size)
    assert_equal("lib/example.rb", result.first[:location])
    assert_equal(10, result.first[:line])
    assert_equal("method", result.first[:method_name])
    assert_equal("param->param", result.first[:separators])
  end

  it "call with multiple offenses parses all offense entries" do
    input = <<~OUTPUT
      lib/example.rb:10: Example#method1
      param->param
      lib/example.rb:20: Example#method2
      param->return,return->raise
    OUTPUT

    result = parser.call(input)

    assert_equal(2, result.size)
    assert_equal("method1", result[0][:method_name])
    assert_equal("param->param", result[0][:separators])
    assert_equal("method2", result[1][:method_name])
    assert_equal("param->return,return->raise", result[1][:separators])
  end

  it "call keeps offenses distinct for methods differing only by punctuation on the same line" do
    input = <<~OUTPUT
      lib/example.rb:10: Example#enabled?
      param->param
      lib/example.rb:10: Example#enabled!
      return->raise
    OUTPUT

    result = parser.call(input)

    assert_equal(2, result.size)

    question_offense = result.find { |o| o[:method_name] == "enabled?" }
    bang_offense = result.find { |o| o[:method_name] == "enabled!" }

    refute_nil(question_offense)
    refute_nil(bang_offense)
    assert_equal("param->param", question_offense[:separators])
    assert_equal("return->raise", bang_offense[:separators])
  end

  it "call keeps offenses distinct for different paths that collapse to the same word characters" do
    input = <<~OUTPUT
      lib/a/b.rb:10: X#y
      param->param
      libab.rb:10: X#y
      return->raise
    OUTPUT

    result = parser.call(input)

    assert_equal(2, result.size)

    nested_offense = result.find { |o| o[:location] == "lib/a/b.rb" }
    flat_offense = result.find { |o| o[:location] == "libab.rb" }

    refute_nil(nested_offense)
    refute_nil(flat_offense)
    assert_equal("param->param", nested_offense[:separators])
    assert_equal("return->raise", flat_offense[:separators])
  end

  it "call keeps pairing intact when a location line is unparseable" do
    input = <<~OUTPUT
      lib/example.rb:10: Example#method1
      param->param
      THIS LINE IS NOT A LOCATION
      param->return
      lib/example.rb:20: Example#method2
      return->raise
    OUTPUT

    result = parser.call(input)

    assert_equal(2, result.size)

    second = result.find { |o| o[:method_name] == "method2" }

    refute_nil(second)
    # The unparseable entry must be dropped alone - it must not shift the
    # separator payloads of the offenses that follow it
    assert_equal("return->raise", second[:separators])
  end
end

# frozen_string_literal: true

describe 'Yard::Lint::Validators::Tags::CollectionType::Parser' do
  attr_reader :parser

  before do
    @parser = Yard::Lint::Validators::Tags::CollectionType::Parser.new
  end

  it 'call with valid yard output parses violations correctly with short style detected' do
    output = <<~OUTPUT
      spec/fixtures/collection_type_examples.rb:25: InvalidHashSyntax#process
      param|Hash<Symbol, String>|short
      spec/fixtures/collection_type_examples.rb:35: InvalidNestedHash#process
      param|Hash<String, Hash<Symbol, Integer>>|short
    OUTPUT

    result = parser.call(output)

    assert_kind_of(Array, result)
    assert_equal(2, result.size)

    assert_equal('spec/fixtures/collection_type_examples.rb', result[0][:location])
    assert_equal(25, result[0][:line])
    assert_equal('InvalidHashSyntax#process', result[0][:object_name])
    assert_equal('param', result[0][:tag_name])
    assert_equal('Hash<Symbol, String>', result[0][:type_string])
    assert_equal('short', result[0][:detected_style])

    assert_equal('spec/fixtures/collection_type_examples.rb', result[1][:location])
    assert_equal(35, result[1][:line])
    assert_equal('InvalidNestedHash#process', result[1][:object_name])
    assert_equal('param', result[1][:tag_name])
    assert_equal('Hash<String, Hash<Symbol, Integer>>', result[1][:type_string])
    assert_equal('short', result[1][:detected_style])
  end

  it 'call with valid yard output parses violations correctly with long style detected' do
    output = <<~OUTPUT
      spec/fixtures/collection_type_examples.rb:42: ValidHashSyntax#process
      param|Hash{Symbol => String}|long
    OUTPUT

    result = parser.call(output)

    assert_kind_of(Array, result)
    assert_equal(1, result.size)

    assert_equal('spec/fixtures/collection_type_examples.rb', result[0][:location])
    assert_equal(42, result[0][:line])
    assert_equal('ValidHashSyntax#process', result[0][:object_name])
    assert_equal('param', result[0][:tag_name])
    assert_equal('Hash{Symbol => String}', result[0][:type_string])
    assert_equal('long', result[0][:detected_style])
  end

  it 'call with empty output returns empty array for nil' do
    assert_equal([], parser.call(nil))
  end

  it 'call with empty output returns empty array for empty string' do
    assert_equal([], parser.call(''))
  end

  it 'call with empty output returns empty array for whitespace only' do
    assert_equal([], parser.call("  \n  \t  "))
  end

  it 'call with malformed output skips lines without proper format' do
    output = <<~OUTPUT
      spec/fixtures/test.rb:10: Test#method
      param|Hash<K, V>|short
      invalid line without pipe
      another invalid line
    OUTPUT

    result = parser.call(output)
    assert_equal(1, result.size)
  end

  it 'call with malformed output skips incomplete violation pairs' do
    output = "spec/fixtures/test.rb:10: Test#method\n"
    result = parser.call(output)
    assert_equal([], result)
  end
end


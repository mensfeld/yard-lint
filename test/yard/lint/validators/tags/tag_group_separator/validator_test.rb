# frozen_string_literal: true

require 'test_helper'


describe 'Yard::Lint::Validators::Tags::TagGroupSeparator::Validator' do
  attr_reader :config, :selection, :validator, :collector


  before do
    @config = Yard::Lint::Config.new
    @selection = ['lib/example.rb']
    @validator = Yard::Lint::Validators::Tags::TagGroupSeparator::Validator.new(config, selection)
    @collector = Yard::Lint::Executor::ResultCollector.new
  end

  it 'initialize inherits from base validator' do
    assert_kind_of(Yard::Lint::Validators::Base, validator)
  end

  it 'initialize stores config and selection' do
    assert_equal(config, validator.config)
    assert_equal(selection, validator.selection)
  end

  it 'in process returns true for in process execution' do
    assert_equal(true, Yard::Lint::Validators::Tags::TagGroupSeparator::Validator.in_process?)
  end

  it 'with properly separated tag groups reports valid' do
    docstring = <<~DOC
      Description of method.

      @param id [String] the ID
      @param name [String] the name

      @return [Object] the result
    DOC

    object = mock_yard_object(docstring: docstring)
    validator.in_process_query(object, collector)
    output = collector.to_stdout
    assert_includes(output, 'valid')
  end

  it 'with missing separator between param and return reports missing separator' do
    docstring = <<~DOC
      Description of method.

      @param id [String] the ID
      @return [Object] the result
    DOC

    object = mock_yard_object(docstring: docstring)
    validator.in_process_query(object, collector)
    output = collector.to_stdout
    assert_includes(output, 'param->return')
  end

  it 'with multiple missing separators reports all missing separators' do
    docstring = <<~DOC
      @param id [String] the ID
      @return [Object] the result
      @raise [Error] when something fails
    DOC

    object = mock_yard_object(docstring: docstring)
    validator.in_process_query(object, collector)
    output = collector.to_stdout
    assert_includes(output, 'param->return')
    assert_includes(output, 'return->error')
  end

  it 'with same group consecutive tags reports valid' do
    docstring = <<~DOC
      @param id [String] the ID
      @param name [String] the name
      @option opts [String] :foo the foo
    DOC

    object = mock_yard_object(docstring: docstring)
    validator.in_process_query(object, collector)
    output = collector.to_stdout
    assert_includes(output, 'valid')
  end

  it 'with empty docstring does not report any issues' do
    object = mock_yard_object(docstring: '')
    validator.in_process_query(object, collector)
    output = collector.to_stdout
    assert_empty(output)
  end

  it 'with alias object skips alias objects' do
    object = mock_yard_object(docstring: '@param id [String]', is_alias: true)
    validator.in_process_query(object, collector)
    output = collector.to_stdout
    assert_empty(output)
  end

  it 'with unknown tags treats unknown tags as their own group' do
    docstring = <<~DOC
      @param id [String] the ID
      @custom_tag some value
    DOC

    object = mock_yard_object(docstring: docstring)
    validator.in_process_query(object, collector)
    output = collector.to_stdout
    assert_includes(output, 'param->custom_tag')
  end

  it 'with multiline tag content handles multiline tags correctly' do
    docstring = <<~DOC
      @param id [String] the ID
        with additional description
        spanning multiple lines
      @param name [String] the name
    DOC

    object = mock_yard_object(docstring: docstring)
    validator.in_process_query(object, collector)
    output = collector.to_stdout
    assert_includes(output, 'valid')
  end

  private

  def mock_yard_object(docstring:, is_alias: false)
    object = stub('object')
    docstring_obj = stub('docstring')

    object.stubs(:is_alias?).returns(is_alias)
    object.stubs(:docstring).returns(docstring_obj)
    object.stubs(:file).returns('lib/example.rb')
    object.stubs(:line).returns(10)
    object.stubs(:title).returns('Example#method')
    docstring_obj.stubs(:all).returns(docstring)

    object
  end
end

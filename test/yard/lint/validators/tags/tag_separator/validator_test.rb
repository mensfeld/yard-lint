# frozen_string_literal: true

describe "Yard::Lint::Validators::Tags::TagSeparator::Validator" do
  attr_reader :config, :selection, :validator, :collector

  before do
    @config = Yard::Lint::Config.new
    @selection = ["lib/example.rb"]
    @validator = Yard::Lint::Validators::Tags::TagSeparator::Validator.new(config, selection)
    @collector = Yard::Lint::Executor::ResultCollector.new
  end

  it "initialize inherits from base validator" do
    assert_kind_of(Yard::Lint::Validators::Base, validator)
  end

  it "initialize stores config and selection" do
    assert_equal(config, validator.config)
    assert_equal(selection, validator.selection)
  end

  it "in process returns true for in process execution" do
    assert_predicate(Yard::Lint::Validators::Tags::TagSeparator::Validator, :in_process?)
  end

  it "with every tag separated reports valid" do
    docstring = <<~DOC
      Description of method.

      @param id [String] the ID

      @param name [String] the name

      @return [Object] the result
    DOC

    object = mock_yard_object(docstring: docstring)
    validator.in_process_query(object, collector)
    output = collector.to_stdout

    assert_includes(output, "valid")
  end

  it "with missing separator between consecutive params reports missing separator" do
    docstring = <<~DOC
      Description of method.

      @param id [String] the ID
      @param name [String] the name
    DOC

    object = mock_yard_object(docstring: docstring)
    validator.in_process_query(object, collector)
    output = collector.to_stdout

    assert_includes(output, "param->param")
  end

  it "with missing separator between param and return reports missing separator" do
    docstring = <<~DOC
      Description of method.

      @param id [String] the ID

      @return [Object] the result
      @raise [Error] on failure
    DOC

    object = mock_yard_object(docstring: docstring)
    validator.in_process_query(object, collector)
    output = collector.to_stdout

    assert_includes(output, "return->raise")
  end

  it "with multiple missing separators reports all missing separators" do
    docstring = <<~DOC
      @param id [String] the ID
      @param name [String] the name
      @return [Object] the result
    DOC

    object = mock_yard_object(docstring: docstring)
    validator.in_process_query(object, collector)
    output = collector.to_stdout

    assert_includes(output, "param->param")
    assert_includes(output, "param->return")
  end

  it "with exempt tag does not report missing separator for exempt tag" do
    exempt_config = Yard::Lint::Config.new(
      "Tags/TagSeparator" => {"Enabled" => true, "Exempt" => ["option"]}
    )
    exempt_validator = Yard::Lint::Validators::Tags::TagSeparator::Validator.new(
      exempt_config, selection
    )
    docstring = <<~DOC
      @param opts [Hash] the options
      @option opts [String] :name the name
      @option opts [Integer] :age the age
    DOC

    object = mock_yard_object(docstring: docstring)
    exempt_validator.in_process_query(object, collector)
    output = collector.to_stdout

    assert_includes(output, "valid")
  end

  it "with require after description reports missing separator after description" do
    rad_config = Yard::Lint::Config.new(
      "Tags/TagSeparator" => {"Enabled" => true, "RequireAfterDescription" => true}
    )
    rad_validator = Yard::Lint::Validators::Tags::TagSeparator::Validator.new(
      rad_config, selection
    )
    docstring = <<~DOC
      Description of method.
      @return [Object] the result
    DOC

    object = mock_yard_object(docstring: docstring)
    rad_validator.in_process_query(object, collector)
    output = collector.to_stdout

    assert_includes(output, "description->return")
  end

  it "with require after description and exempt tag reports missing separator after description" do
    rad_config = Yard::Lint::Config.new(
      "Tags/TagSeparator" => {
        "Enabled" => true,
        "RequireAfterDescription" => true,
        "Exempt" => ["option"]
      }
    )
    rad_validator = Yard::Lint::Validators::Tags::TagSeparator::Validator.new(
      rad_config, selection
    )
    docstring = <<~DOC
      Description of method.
      @option opts [String] :name the name
    DOC

    object = mock_yard_object(docstring: docstring)
    rad_validator.in_process_query(object, collector)
    output = collector.to_stdout

    assert_includes(output, "description->option")
  end

  it "with a tag as the first line and no description reports valid" do
    docstring = <<~DOC
      @param id [String] the ID
    DOC

    object = mock_yard_object(docstring: docstring)
    validator.in_process_query(object, collector)
    output = collector.to_stdout

    assert_includes(output, "valid")
  end

  it "with description immediately followed by a tag and require after description disabled reports valid" do
    docstring = <<~DOC
      Description of method.
      @return [Object] the result
    DOC

    object = mock_yard_object(docstring: docstring)
    validator.in_process_query(object, collector)
    output = collector.to_stdout

    assert_includes(output, "valid")
  end

  it "with empty docstring does not report any issues" do
    object = mock_yard_object(docstring: "")
    validator.in_process_query(object, collector)
    output = collector.to_stdout

    assert_empty(output)
  end

  it "with alias object skips alias objects" do
    object = mock_yard_object(docstring: "@param id [String]", is_alias: true)
    validator.in_process_query(object, collector)
    output = collector.to_stdout

    assert_empty(output)
  end

  it "with multiline tag content handles multiline tags correctly" do
    docstring = <<~DOC
      @param id [String] the ID
        with additional description
        spanning multiple lines

      @param name [String] the name
    DOC

    object = mock_yard_object(docstring: docstring)
    validator.in_process_query(object, collector)
    output = collector.to_stdout

    assert_includes(output, "valid")
  end

  private

  def mock_yard_object(docstring:, is_alias: false, type: :method)
    object = stub("object")
    docstring_obj = stub("docstring")

    object.stubs(:type).returns(type)
    object.stubs(:is_alias?).returns(is_alias)
    object.stubs(:docstring).returns(docstring_obj)
    object.stubs(:file).returns("lib/example.rb")
    object.stubs(:line).returns(10)
    object.stubs(:title).returns("Example#method")
    docstring_obj.stubs(:all).returns(docstring)

    object
  end
end

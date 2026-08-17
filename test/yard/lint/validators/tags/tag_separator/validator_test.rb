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

  it "in process visits private objects" do
    # module_function_copy? skips the normalized half of a module_function pair
    # on the understanding that its authored twin is linted instead. In two of
    # the three forms that twin is the private instance method, so narrowing
    # this to :public would leave those methods unlinted entirely.
    assert_equal(:all, Yard::Lint::Validators::Tags::TagSeparator::Validator.in_process_visibility)
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

  it "with the rebuilt half of a module_function pair skips the object" do
    # What YARD's copy_to leaves behind: the same content, none of the layout
    object = mock_module_function_object(
      docstring: "Description of method.\n@param [String] id\n  the ID\n@return [Object] the result",
      scope: :instance,
      twin: mock_module_function_twin(scope: :class, line_range: 4..8)
    )
    validator.in_process_query(object, collector)

    assert_empty(collector.to_stdout)
  end

  it "with the authored half of a module_function pair reports its offenses" do
    object = mock_module_function_object(
      docstring: "Description of method.\n\n@param id [String] the ID\n@return [Object] the result",
      scope: :class,
      line_range: 4..8,
      twin: mock_module_function_twin(scope: :instance, line_range: nil)
    )
    validator.in_process_query(object, collector)

    assert_includes(collector.to_stdout, "param->return")
  end

  it "with module_function def skips the class method half" do
    # `module_function def name` leaves neither half with a docstring line range;
    # there the class method is the copy and the instance method is the original
    object = mock_module_function_object(
      docstring: "Description of method.\n@param [String] id\n  the ID\n@return [Object] the result",
      scope: :class,
      twin: mock_module_function_twin(scope: :instance, line_range: nil)
    )
    validator.in_process_query(object, collector)

    assert_empty(collector.to_stdout)
  end

  it "with module_function def reports the instance method half" do
    object = mock_module_function_object(
      docstring: "Description of method.\n\n@param id [String] the ID\n@return [Object] the result",
      scope: :instance,
      twin: mock_module_function_twin(scope: :class, line_range: nil)
    )
    validator.in_process_query(object, collector)

    assert_includes(collector.to_stdout, "param->return")
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
    docstring_obj.stubs(:line_range).returns(nil)

    object
  end

  # One half of the pair YARD registers for a module_function definition. Both
  # halves sit at the same file and line, and YARD flags only the class method
  # as a module function.
  def mock_module_function_object(docstring:, scope:, twin:, line_range: nil)
    object = mock_yard_object(docstring: docstring)
    namespace = stub("namespace")

    object.stubs(:scope).returns(scope)
    object.stubs(:name).returns(:method_name)
    object.stubs(:module_function?).returns(scope == :class)
    object.stubs(:namespace).returns(namespace)
    object.docstring.stubs(:line_range).returns(line_range)
    namespace.stubs(:child).returns(twin)

    object
  end

  def mock_module_function_twin(scope:, line_range:)
    twin = stub("twin")
    twin_docstring = stub("twin_docstring")

    twin.stubs(:file).returns("lib/example.rb")
    twin.stubs(:line).returns(10)
    twin.stubs(:module_function?).returns(scope == :class)
    twin.stubs(:docstring).returns(twin_docstring)
    twin_docstring.stubs(:line_range).returns(line_range)

    twin
  end
end

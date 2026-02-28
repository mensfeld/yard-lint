# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsTagGroupSeparatorValidatorTest < Minitest::Test
  attr_reader :config, :selection, :validator, :collector

  def setup
    @config = Yard::Lint::Config.new
    @selection = ['lib/example.rb']
    @validator = Yard::Lint::Validators::Tags::TagGroupSeparator::Validator.new(config, selection)
    @collector = Yard::Lint::Executor::ResultCollector.new
  end

  def test_initialize_inherits_from_base_validator
    assert_kind_of(Yard::Lint::Validators::Base, validator)
  end

  def test_initialize_stores_config_and_selection
    assert_equal(config, validator.config)
    assert_equal(selection, validator.selection)
  end

  def test_in_process_returns_true_for_in_process_execution
    assert_equal(true, Yard::Lint::Validators::Tags::TagGroupSeparator::Validator.in_process?)
  end

  def test_with_properly_separated_tag_groups_reports_valid
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

  def test_with_missing_separator_between_param_and_return_reports_missing_separator
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

  def test_with_multiple_missing_separators_reports_all_missing_separators
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

  def test_with_same_group_consecutive_tags_reports_valid
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

  def test_with_empty_docstring_does_not_report_any_issues
    object = mock_yard_object(docstring: '')
    validator.in_process_query(object, collector)
    output = collector.to_stdout
    assert_empty(output)
  end

  def test_with_alias_object_skips_alias_objects
    object = mock_yard_object(docstring: '@param id [String]', is_alias: true)
    validator.in_process_query(object, collector)
    output = collector.to_stdout
    assert_empty(output)
  end

  def test_with_unknown_tags_treats_unknown_tags_as_their_own_group
    docstring = <<~DOC
      @param id [String] the ID
      @custom_tag some value
    DOC

    object = mock_yard_object(docstring: docstring)
    validator.in_process_query(object, collector)
    output = collector.to_stdout
    assert_includes(output, 'param->custom_tag')
  end

  def test_with_multiline_tag_content_handles_multiline_tags_correctly
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

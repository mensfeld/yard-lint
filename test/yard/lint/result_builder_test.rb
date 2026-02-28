# frozen_string_literal: true

require 'test_helper'

class YardLintResultBuilderTest < Minitest::Test
  attr_reader :config, :builder

  def setup
    @config = Yard::Lint::Config.new
    @builder = Yard::Lint::ResultBuilder.new(@config)
  end

  def test_initialize_stores_config
    assert_equal(@config, @builder.config)
  end

  def test_build_with_composite_validator_combines_results_from_parent_and_child_validators
    validator_name = 'Documentation/UndocumentedObjects'
    raw_results = {
      undocumented_objects: {
        stdout: "file.rb:10: MyClass\nfile.rb:20: MyModule",
        stderr: '',
        exit_code: 0
      },
      undocumented_boolean_methods: {
        stdout: 'file.rb:30: MyClass#valid?',
        stderr: '',
        exit_code: 0
      }
    }

    result = @builder.build(validator_name, raw_results)

    assert_kind_of(Yard::Lint::Results::Base, result)
    # Should combine offenses from both validators
    assert_equal(3, result.offenses.size)
  end

  def test_build_with_composite_validator_returns_nil_when_all_validators_have_no_output
    validator_name = 'Documentation/UndocumentedObjects'
    empty_results = {
      undocumented_objects: { stdout: '', stderr: '', exit_code: 0 },
      undocumented_boolean_methods: { stdout: '', stderr: '', exit_code: 0 }
    }
    result = @builder.build(validator_name, empty_results)

    assert_nil(result)
  end

  def test_build_with_composite_validator_includes_partial_results_when_only_one_child_has_output
    validator_name = 'Documentation/UndocumentedObjects'
    partial_results = {
      undocumented_objects: { stdout: '', stderr: '', exit_code: 0 },
      undocumented_boolean_methods: {
        stdout: 'file.rb:30: MyClass#valid?',
        stderr: '',
        exit_code: 0
      }
    }
    result = @builder.build(validator_name, partial_results)

    refute_nil(result)
    assert_equal(1, result.offenses.size)
  end

  def test_build_with_composite_child_validator_returns_nil
    validator_name = 'Documentation/UndocumentedBooleanMethods'
    raw_results = {
      undocumented_boolean_methods: {
        stdout: 'file.rb:30: MyClass#valid?',
        stderr: '',
        exit_code: 0
      }
    }

    result = @builder.build(validator_name, raw_results)

    assert_nil(result)
  end

  def test_build_with_warnings_unknowntag_discovers_and_uses_parser
    validator_name = 'Warnings/UnknownTag'
    raw_results = {
      unknown_tag: {
        stdout: "[warn]: Unknown tag @example1 in file `file.rb` near line 5\n",
        stderr: '',
        exit_code: 0
      }
    }

    result = @builder.build(validator_name, raw_results)

    assert_kind_of(Yard::Lint::Results::Base, result)
    # Should have parsed offenses
    assert_operator(result.offenses.size, :>=, 1)
  end

  def test_build_with_warnings_unknowntag_returns_nil_when_no_warnings
    empty_results = { unknown_tag: { stdout: '', stderr: '', exit_code: 0 } }
    result = @builder.build('Warnings/UnknownTag', empty_results)

    assert_nil(result)
  end

  def test_build_with_standard_validator_returns_nil_when_no_output
    result = @builder.build('Tags/Order', {})

    assert_nil(result)
  end

  def test_build_with_standard_validator_returns_nil_when_output_is_empty
    empty_results = { tags_order: { stdout: '', stderr: '', exit_code: 0 } }
    result = @builder.build('Tags/Order', empty_results)

    assert_nil(result)
  end

  def test_parser_discovery_discovers_parser_for_unknowntag_validator
    result = @builder.build(
      'Warnings/UnknownTag',
      {
        unknown_tag: {
          stdout: "[warn]: Unknown tag @test in file `file.rb` near line 5\n",
          stderr: '',
          exit_code: 0
        }
      }
    )

    # Parser discovered and used
    assert_kind_of(Yard::Lint::Results::Base, result)
    assert_operator(result.offenses.size, :>=, 1)
  end

  def test_composite_detection_skips_composite_children_automatically
    # UndocumentedBooleanMethods is a child of UndocumentedObjects composite
    result = @builder.build(
      'Documentation/UndocumentedBooleanMethods',
      {
        undocumented_boolean_methods: {
          stdout: 'file.rb:30: MyClass#valid?',
          stderr: '',
          exit_code: 0
        }
      }
    )

    assert_nil(result)
  end

  def test_composite_detection_processes_parent_composites
    # UndocumentedObjects is the parent composite
    result = @builder.build(
      'Documentation/UndocumentedObjects',
      {
        undocumented_objects: {
          stdout: 'file.rb:10: MyClass',
          stderr: '',
          exit_code: 0
        }
      }
    )

    refute_nil(result)
  end
end

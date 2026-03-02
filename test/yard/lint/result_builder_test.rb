# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::ResultBuilder' do
  attr_reader :config, :builder

  before do
    @config = Yard::Lint::Config.new
    @builder = Yard::Lint::ResultBuilder.new(@config)
  end

  it 'initialize stores config' do
    assert_equal(@config, @builder.config)
  end

  it 'build with composite validator combines results from parent and child validators' do
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

  it 'build with composite validator returns nil when all validators have no output' do
    validator_name = 'Documentation/UndocumentedObjects'
    empty_results = {
      undocumented_objects: { stdout: '', stderr: '', exit_code: 0 },
      undocumented_boolean_methods: { stdout: '', stderr: '', exit_code: 0 }
    }
    result = @builder.build(validator_name, empty_results)

    assert_nil(result)
  end

  it 'build with composite validator includes partial results when only one child has output' do
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

  it 'build with composite child validator returns nil' do
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

  it 'build with warnings unknowntag discovers and uses parser' do
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

  it 'build with warnings unknowntag returns nil when no warnings' do
    empty_results = { unknown_tag: { stdout: '', stderr: '', exit_code: 0 } }
    result = @builder.build('Warnings/UnknownTag', empty_results)

    assert_nil(result)
  end

  it 'build with standard validator returns nil when no output' do
    result = @builder.build('Tags/Order', {})

    assert_nil(result)
  end

  it 'build with standard validator returns nil when output is empty' do
    empty_results = { tags_order: { stdout: '', stderr: '', exit_code: 0 } }
    result = @builder.build('Tags/Order', empty_results)

    assert_nil(result)
  end

  it 'parser discovery discovers parser for unknowntag validator' do
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

  it 'composite detection skips composite children automatically' do
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

  it 'composite detection processes parent composites' do
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


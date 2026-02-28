# frozen_string_literal: true

require 'test_helper'

class YardLintExecutorQueryExecutorTest < Minitest::Test
  attr_reader :registry, :executor

  def setup
    @registry = stub('registry')
    @executor = Yard::Lint::Executor::QueryExecutor.new(@registry)
  end

  def test_initialize_stores_the_registry
    assert_equal(@registry, @executor.instance_variable_get(:@registry))
  end

  def test_execute_returns_a_result_hash_with_stdout_stderr_and_exit_code
    config = Yard::Lint::Config.new
    validator_class = Class.new(Yard::Lint::Validators::Base) do
      def self.validator_name
        'Test/Validator'
      end

      def self.in_process_visibility
        :public
      end

      def in_process_query(object, collector)
        collector.puts("test:#{object.path}:1")
      end
    end
    validator = validator_class.new(config, [])

    mock_object = stub(
      file: 'lib/test.rb',
      line: 10,
      path: 'TestClass#method',
      visibility: :public
    )

    @registry.stubs(:objects_for_validator).returns([mock_object])
    config.stubs(:validator_exclude).with('Test/Validator').returns([])

    result = @executor.execute(validator)

    assert(result.key?(:stdout))
    assert(result.key?(:stderr))
    assert(result.key?(:exit_code))
    assert_equal('', result[:stderr])
    assert_equal(0, result[:exit_code])
  end

  def test_execute_calls_registry_objects_for_validator_with_correct_visibility
    config = Yard::Lint::Config.new
    validator_class = Class.new(Yard::Lint::Validators::Base) do
      def self.validator_name
        'Test/Validator'
      end

      def self.in_process_visibility
        :public
      end

      def in_process_query(object, collector)
        collector.puts("test:#{object.path}:1")
      end
    end
    validator = validator_class.new(config, [])

    mock_object = stub(
      file: 'lib/test.rb',
      line: 10,
      path: 'TestClass#method',
      visibility: :public
    )

    @registry.expects(:objects_for_validator).with(
      visibility: :public,
      file_excludes: [],
      file_selection: nil
    ).returns([mock_object])
    config.stubs(:validator_exclude).with('Test/Validator').returns([])

    @executor.execute(validator)
  end

  def test_execute_passes_file_selection_to_registry_when_provided
    config = Yard::Lint::Config.new
    validator_class = Class.new(Yard::Lint::Validators::Base) do
      def self.validator_name
        'Test/Validator'
      end

      def self.in_process_visibility
        :public
      end

      def in_process_query(object, collector)
        collector.puts("test:#{object.path}:1")
      end
    end
    validator = validator_class.new(config, [])

    mock_object = stub(
      file: 'lib/test.rb',
      line: 10,
      path: 'TestClass#method',
      visibility: :public
    )

    @registry.expects(:objects_for_validator).with(
      visibility: :public,
      file_excludes: [],
      file_selection: ['lib/foo.rb']
    ).returns([mock_object])
    config.stubs(:validator_exclude).with('Test/Validator').returns([])

    @executor.execute(validator, file_selection: ['lib/foo.rb'])
  end

  def test_execute_skips_objects_without_file_info
    config = Yard::Lint::Config.new
    validator_class = Class.new(Yard::Lint::Validators::Base) do
      def self.validator_name
        'Test/Validator'
      end

      def self.in_process_visibility
        :public
      end

      def in_process_query(object, collector)
        collector.puts("test:#{object.path}:1")
      end
    end
    validator = validator_class.new(config, [])

    object_without_file = stub(
      file: nil,
      line: 10,
      path: 'NoFile#method'
    )
    @registry.stubs(:objects_for_validator).returns([object_without_file])
    config.stubs(:validator_exclude).with('Test/Validator').returns([])

    result = @executor.execute(validator)

    assert_equal('', result[:stdout])
  end

  def test_execute_skips_objects_without_line_info
    config = Yard::Lint::Config.new
    validator_class = Class.new(Yard::Lint::Validators::Base) do
      def self.validator_name
        'Test/Validator'
      end

      def self.in_process_visibility
        :public
      end

      def in_process_query(object, collector)
        collector.puts("test:#{object.path}:1")
      end
    end
    validator = validator_class.new(config, [])

    object_without_line = stub(
      file: 'lib/test.rb',
      line: nil,
      path: 'NoLine#method'
    )
    @registry.stubs(:objects_for_validator).returns([object_without_line])
    config.stubs(:validator_exclude).with('Test/Validator').returns([])

    result = @executor.execute(validator)

    assert_equal('', result[:stdout])
  end

  def test_execute_processes_objects_with_both_file_and_line_info
    config = Yard::Lint::Config.new
    validator_class = Class.new(Yard::Lint::Validators::Base) do
      def self.validator_name
        'Test/Validator'
      end

      def self.in_process_visibility
        :public
      end

      def in_process_query(object, collector)
        collector.puts("test:#{object.path}:1")
      end
    end
    validator = validator_class.new(config, [])

    mock_object = stub(
      file: 'lib/test.rb',
      line: 10,
      path: 'TestClass#method',
      visibility: :public
    )

    @registry.stubs(:objects_for_validator).returns([mock_object])
    config.stubs(:validator_exclude).with('Test/Validator').returns([])

    result = @executor.execute(validator)

    assert_includes(result[:stdout], 'test:TestClass#method:1')
  end

  def test_execute_with_file_excludes_from_config_passes_excludes_to_registry
    config = Yard::Lint::Config.new
    validator_class = Class.new(Yard::Lint::Validators::Base) do
      def self.validator_name
        'Test/Validator'
      end

      def self.in_process_visibility
        :public
      end

      def in_process_query(object, collector)
        collector.puts("test:#{object.path}:1")
      end
    end
    validator = validator_class.new(config, [])

    mock_object = stub(
      file: 'lib/test.rb',
      line: 10,
      path: 'TestClass#method',
      visibility: :public
    )

    config.stubs(:validator_exclude).with('Test/Validator').returns(['spec/**/*'])
    @registry.expects(:objects_for_validator).with(
      visibility: :public,
      file_excludes: ['spec/**/*'],
      file_selection: nil
    ).returns([mock_object])

    @executor.execute(validator)
  end

  # determine_visibility tests

  def test_determine_visibility_when_validator_has_no_config_uses_validator_in_process_visibility
    mock_object = stub(
      file: 'lib/test.rb',
      line: 10,
      path: 'TestClass#method',
      visibility: :public
    )

    validator_class = Class.new(Yard::Lint::Validators::Base) do
      def self.validator_name
        'Tags/Order'
      end

      def self.in_process_visibility
        :all
      end

      def in_process_query(_object, _collector); end
    end

    @registry.expects(:objects_for_validator).with(
      has_entry(:visibility, :all)
    ).returns([mock_object])

    validator = validator_class.new(nil, [])
    @executor.execute(validator)
  end

  def test_determine_visibility_when_config_has_private_in_global_yardoptions_uses_all_visibility
    mock_object = stub(
      file: 'lib/test.rb',
      line: 10,
      path: 'TestClass#method',
      visibility: :public
    )

    config = Yard::Lint::Config.new(
      {
        'AllValidators' => { 'YardOptions' => ['--private'] },
        'Tags/Order' => { 'Enabled' => true }
      }
    )

    validator_class = Class.new(Yard::Lint::Validators::Base) do
      def self.validator_name
        'Tags/Order'
      end

      def self.in_process_visibility
        :public
      end

      def in_process_query(_object, _collector); end
    end

    @registry.expects(:objects_for_validator).with(
      has_entry(:visibility, :all)
    ).returns([mock_object])

    validator = validator_class.new(config, [])
    @executor.execute(validator)
  end

  def test_determine_visibility_when_config_has_protected_in_global_yardoptions_uses_all_visibility
    mock_object = stub(
      file: 'lib/test.rb',
      line: 10,
      path: 'TestClass#method',
      visibility: :public
    )

    config = Yard::Lint::Config.new(
      {
        'AllValidators' => { 'YardOptions' => ['--protected'] },
        'Tags/Order' => { 'Enabled' => true }
      }
    )

    validator_class = Class.new(Yard::Lint::Validators::Base) do
      def self.validator_name
        'Tags/Order'
      end

      def self.in_process_visibility
        :public
      end

      def in_process_query(_object, _collector); end
    end

    @registry.expects(:objects_for_validator).with(
      has_entry(:visibility, :all)
    ).returns([mock_object])

    validator = validator_class.new(config, [])
    @executor.execute(validator)
  end

  def test_determine_visibility_when_validator_has_explicit_empty_yardoptions_uses_public_visibility
    mock_object = stub(
      file: 'lib/test.rb',
      line: 10,
      path: 'TestClass#method',
      visibility: :public
    )

    config = Yard::Lint::Config.new(
      {
        'AllValidators' => { 'YardOptions' => ['--private'] },
        'Tags/Order' => { 'Enabled' => true, 'YardOptions' => [] }
      }
    )

    validator_class = Class.new(Yard::Lint::Validators::Base) do
      def self.validator_name
        'Tags/Order'
      end

      def self.in_process_visibility
        :all
      end

      def in_process_query(_object, _collector); end
    end

    @registry.expects(:objects_for_validator).with(
      has_entry(:visibility, :public)
    ).returns([mock_object])

    validator = validator_class.new(config, [])
    @executor.execute(validator)
  end

  def test_determine_visibility_when_validator_has_private_in_its_own_yardoptions_uses_all_visibility
    mock_object = stub(
      file: 'lib/test.rb',
      line: 10,
      path: 'TestClass#method',
      visibility: :public
    )

    config = Yard::Lint::Config.new(
      {
        'AllValidators' => { 'YardOptions' => [] },
        'Tags/Order' => { 'Enabled' => true, 'YardOptions' => ['--private'] }
      }
    )

    validator_class = Class.new(Yard::Lint::Validators::Base) do
      def self.validator_name
        'Tags/Order'
      end

      def self.in_process_visibility
        :public
      end

      def in_process_query(_object, _collector); end
    end

    @registry.expects(:objects_for_validator).with(
      has_entry(:visibility, :all)
    ).returns([mock_object])

    validator = validator_class.new(config, [])
    @executor.execute(validator)
  end

  def test_determine_visibility_when_no_yardoptions_key_and_global_is_empty_falls_back_to_validator_default
    mock_object = stub(
      file: 'lib/test.rb',
      line: 10,
      path: 'TestClass#method',
      visibility: :public
    )

    config = Yard::Lint::Config.new(
      {
        'AllValidators' => { 'YardOptions' => [] },
        'Tags/Order' => { 'Enabled' => true }
      }
    )

    validator_class = Class.new(Yard::Lint::Validators::Base) do
      def self.validator_name
        'Tags/Order'
      end

      def self.in_process_visibility
        :all
      end

      def in_process_query(_object, _collector); end
    end

    @registry.expects(:objects_for_validator).with(
      has_entry(:visibility, :all)
    ).returns([mock_object])

    validator = validator_class.new(config, [])
    @executor.execute(validator)
  end

  # Error handling tests

  def test_error_handling_when_validator_raises_notimplementederror_re_raises_the_error
    config = Yard::Lint::Config.new
    mock_object = stub(
      file: 'lib/test.rb',
      line: 10,
      path: 'TestClass#method',
      visibility: :public
    )
    @registry.stubs(:objects_for_validator).returns([mock_object])

    validator_class = Class.new(Yard::Lint::Validators::Base) do
      def self.validator_name
        'Test/Validator'
      end

      def self.in_process_visibility
        :public
      end

      def in_process_query(_object, _collector)
        raise NotImplementedError, 'not implemented'
      end
    end

    validator = validator_class.new(config, [])
    config.stubs(:validator_exclude).returns([])

    assert_raises(NotImplementedError) { @executor.execute(validator) }
  end

  def test_error_handling_when_validator_raises_nomethoderror_re_raises_the_error
    config = Yard::Lint::Config.new
    mock_object = stub(
      file: 'lib/test.rb',
      line: 10,
      path: 'TestClass#method',
      visibility: :public
    )
    @registry.stubs(:objects_for_validator).returns([mock_object])

    validator_class = Class.new(Yard::Lint::Validators::Base) do
      def self.validator_name
        'Test/Validator'
      end

      def self.in_process_visibility
        :public
      end

      def in_process_query(_object, _collector)
        raise NoMethodError, 'undefined method'
      end
    end

    validator = validator_class.new(config, [])
    config.stubs(:validator_exclude).returns([])

    assert_raises(NoMethodError) { @executor.execute(validator) }
  end

  def test_error_handling_when_validator_raises_standarderror_catches_the_error_and_continues
    config = Yard::Lint::Config.new
    mock_object = stub(
      file: 'lib/test.rb',
      line: 10,
      path: 'TestClass#method',
      visibility: :public
    )
    @registry.stubs(:objects_for_validator).returns([mock_object])

    validator_class = Class.new(Yard::Lint::Validators::Base) do
      def self.validator_name
        'Test/Validator'
      end

      def self.in_process_visibility
        :public
      end

      def in_process_query(_object, _collector)
        raise StandardError, 'some error'
      end
    end

    validator = validator_class.new(config, [])
    config.stubs(:validator_exclude).returns([])

    @executor.execute(validator)
  end

  def test_error_handling_when_validator_raises_standarderror_returns_empty_result
    config = Yard::Lint::Config.new
    mock_object = stub(
      file: 'lib/test.rb',
      line: 10,
      path: 'TestClass#method',
      visibility: :public
    )
    @registry.stubs(:objects_for_validator).returns([mock_object])

    validator_class = Class.new(Yard::Lint::Validators::Base) do
      def self.validator_name
        'Test/Validator'
      end

      def self.in_process_visibility
        :public
      end

      def in_process_query(_object, _collector)
        raise StandardError, 'some error'
      end
    end

    validator = validator_class.new(config, [])
    config.stubs(:validator_exclude).returns([])

    result = @executor.execute(validator)

    assert_equal('', result[:stdout])
    assert_equal(0, result[:exit_code])
  end
end

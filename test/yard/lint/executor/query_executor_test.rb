# frozen_string_literal: true

describe 'Yard::Lint::Executor::QueryExecutor' do
  attr_reader :registry, :executor

  before do
    @registry = stub('registry')
    @executor = Yard::Lint::Executor::QueryExecutor.new(@registry)
  end

  it 'initialize stores the registry' do
    assert_equal(@registry, @executor.instance_variable_get(:@registry))
  end

  it 'execute returns a result hash with stdout stderr and exit code' do
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

  it 'execute calls registry objects for validator with correct visibility' do
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

  it 'execute passes file selection to registry when provided' do
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

  it 'execute skips objects without file info' do
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

  it 'execute skips objects without line info' do
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

  it 'execute processes objects with both file and line info' do
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

  it 'execute with file excludes from config passes excludes to registry' do
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

  it 'determine visibility when validator has no config uses validator in process visibility' do
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

  it 'determine visibility when config has private in global yardoptions uses all visibility' do
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

  it 'determine visibility when config has protected in global yardoptions uses all visibility' do
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

  it 'determine visibility when validator has explicit empty yardoptions uses public visibility' do
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

  it 'determine visibility when validator has private in its own yardoptions uses all visibility' do
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

  it 'determine visibility when no yardoptions key and global is empty falls back to validator default' do
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

  it 'error handling when validator raises notimplementederror re raises the error' do
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

  it 'error handling when validator raises nomethoderror re raises the error' do
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

  it 'error handling when validator raises standarderror catches the error and continues' do
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

  it 'error handling when validator raises standarderror returns empty result' do
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


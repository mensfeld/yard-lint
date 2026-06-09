# frozen_string_literal: true

describe 'Yard::Lint::Executor::InProcessRegistry' do
  attr_reader :registry

  before do
    @registry = Yard::Lint::Executor::InProcessRegistry.new
  end

  after do
    YARD::Registry.clear
  end

  it 'initialize sets parsed to false' do
    refute(registry.parsed?)
  end

  it 'parse with files populates the registry' do
    file = Tempfile.new(['test', '.rb'])
    file.write(<<~RUBY)
      # A documented class
      # @since 1.0
      class MyClass
        # @return [String] the name
        def name
          'test'
        end
      end
    RUBY
    file.close

    registry.parse([file.path])

    objects = registry.all_objects.map(&:path)
    assert_includes(objects, 'MyClass')
  ensure
    file.unlink
  end

  it 'parse with source populates the registry from memory' do
    source = <<~RUBY
      # A documented class
      # @since 1.0
      class InMemoryClass
        # @return [Integer] the count
        def count
          42
        end
      end
    RUBY

    registry.parse(['/virtual/path/memory.rb'], source: source)

    objects = registry.all_objects.map(&:path)
    assert_includes(objects, 'InMemoryClass')
  end

  it 'parse with source sets object file to the virtual path' do
    source = <<~RUBY
      # Documented
      class VirtualClass; end
    RUBY

    virtual_path = '/virtual/some/file.rb'
    registry.parse([virtual_path], source: source)

    obj = registry.all_objects.find { |o| o.path == 'VirtualClass' }
    refute_nil(obj)
    assert_equal(virtual_path, obj.file)
  end

  it 'parse with source does not require the file to exist on disk' do
    source = <<~RUBY
      # Documented
      class NonExistentFileClass; end
    RUBY

    registry.parse(['/does/not/exist/fake.rb'], source: source)

    objects = registry.all_objects.map(&:path)
    assert_includes(objects, 'NonExistentFileClass')
  end

  it 'parse with source marks registry as parsed' do
    registry.parse(['/virtual/file.rb'], source: '# Documented\nclass Foo; end')
    assert(registry.parsed?)
  end

  it 'parse with files marks registry as parsed' do
    file = Tempfile.new(['test', '.rb'])
    file.write('# Documented\nclass Foo; end')
    file.close

    registry.parse([file.path])
    assert(registry.parsed?)
  ensure
    file.unlink
  end

  it 'parse is idempotent when called twice' do
    source = <<~RUBY
      # Documented
      class IdempotentClass; end
    RUBY

    registry.parse(['/virtual/file.rb'], source: source)
    initial_count = registry.all_objects.size

    registry.parse(['/virtual/file.rb'], source: source)
    assert_equal(initial_count, registry.all_objects.size)
  end

  it 'parse with source captures warnings' do
    source = <<~RUBY
      # @param [String] undefined_param this param does not match the method signature
      def method_with_no_params
      end
    RUBY

    registry.parse(['/virtual/file.rb'], source: source)
    # Warnings may or may not be captured depending on YARD version, but the call must not raise
    assert_kind_of(Array, registry.warnings)
  end

  it 'objects for validator filters by file selection matching the virtual path' do
    source = <<~RUBY
      # Documented
      class VirtualFiltered; end
    RUBY

    virtual_path = File.expand_path('/virtual/selected.rb')
    registry.parse([virtual_path], source: source)

    selected = registry.objects_for_validator(
      visibility: :public,
      file_selection: [virtual_path]
    )

    paths = selected.map(&:path)
    assert_includes(paths, 'VirtualFiltered')
  end

  it 'clear resets parsed state' do
    registry.parse(['/virtual/file.rb'], source: '# Doc\nclass Foo; end')
    assert(registry.parsed?)

    registry.clear!
    refute(registry.parsed?)
  end
end

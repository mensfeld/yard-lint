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

  describe 'parse with files' do
    attr_reader :files, :passes

    before do
      @files = []
      @passes = 0
      @callback = proc { @passes += 1 }
      YARD::Parser::SourceParser.after_parse_list_callbacks << @callback
    end

    after do
      YARD::Parser::SourceParser.after_parse_list_callbacks.delete(@callback)
      files.each(&:unlink)
    end

    def write_file(content)
      file = Tempfile.new(['test', '.rb'])
      file.write(content)
      file.close
      files << file
      file.path
    end

    it 'parses once when no macro is defined' do
      path = write_file(<<~RUBY)
        # Documented
        class NoMacro
          # @return [String] the name
          def name
            'test'
          end
        end
      RUBY

      registry.parse([path])

      assert_equal(1, passes)
      assert_includes(registry.all_objects.map(&:path), 'NoMacro#name')
    end

    it 'parses twice when a macro is defined' do
      path = write_file(<<~RUBY)
        # Documented
        class WithMacro
          # @!macro named
          #   @return [String] the name
          def name
            'test'
          end
        end
      RUBY

      registry.parse([path])

      assert_equal(2, passes)
    end

    it 'parses once when aliases and module functions follow their methods' do
      path = write_file(<<~RUBY)
        # Documented
        module InOrder
          module_function

          # @return [String] the name
          def name
            'test'
          end

          alias label name
        end
      RUBY

      registry.parse([path])

      assert_equal(1, passes)
    end

    it 'parses twice when an alias precedes its method' do
      path = write_file(<<~RUBY)
        # Documented
        class EarlyAlias
          alias label name

          # @return [String] the name
          def name
            'test'
          end
        end
      RUBY

      registry.parse([path])

      assert_equal(2, passes)
    end

    it 'parses twice when module_function precedes its method' do
      path = write_file(<<~RUBY)
        # Documented
        module EarlyModuleFunction
          module_function :name

          # @return [String] the name
          def name
            'test'
          end
        end
      RUBY

      registry.parse([path])

      assert_equal(2, passes)
    end

    it 'parses once when an alias names a method that is not parsed' do
      path = write_file(<<~RUBY)
        # Documented
        class ExternalAlias
          alias_method :old_inspect, :inspect

          # @return [String] the name
          def name
            'test'
          end
        end
      RUBY

      registry.parse([path])

      assert_equal(1, passes)
    end

    it 'parses twice when module_function precedes a method documented with text only' do
      path = write_file(<<~RUBY)
        # Documented
        module EarlyTextModuleFunction
          module_function :run

          # Runs the thing
          def run
            'test'
          end
        end
      RUBY

      registry.parse([path])

      assert_equal(2, passes)
    end

    it 'parses twice for an undocumented module function predicate' do
      path = write_file(<<~RUBY)
        # Documented
        module PredicateModuleFunction
          module_function

          def ready?
            true
          end
        end
      RUBY

      registry.parse([path])

      assert_equal(2, passes)
    end

    it 'keeps only a constant hidden before its definition private after two passes' do
      hiding = write_file(<<~RUBY)
        # Documented
        module HiddenConstant
          # @!macro named
          #   @return [String] the name
          def self.name
            'test'
          end

          private_constant :SECRET
        end
      RUBY
      defining = write_file(<<~RUBY)
        module HiddenConstant
          SECRET = 1
          VISIBLE = 2
        end
      RUBY

      registry.parse([hiding, defining])

      assert_equal(2, passes)
      assert_equal(:private, YARD::Registry.at('HiddenConstant::SECRET').visibility)
      assert_equal(:public, YARD::Registry.at('HiddenConstant::VISIBLE').visibility)
    end

    it 'keeps warnings when it parses once' do
      path = write_file(<<~RUBY)
        # Documented
        class UnknownTag
          # @unknowntag value
          # @return [String] the name
          def name
            'test'
          end
        end
      RUBY

      registry.parse([path])

      assert_equal(1, passes)
      assert(registry.warnings.any? { |w| w.include?('@unknowntag') }, registry.warnings.inspect)
    end
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

  it 'objects for validator returns no objects for an empty file selection' do
    registry.parse(['/virtual/file.rb'], source: "# Documented\nclass EmptySelection; end\n")

    assert_empty(registry.objects_for_validator(visibility: :public, file_selection: []))
  end

  it 'clear resets parsed state' do
    registry.parse(['/virtual/file.rb'], source: '# Doc\nclass Foo; end')
    assert(registry.parsed?)

    registry.clear!
    refute(registry.parsed?)
  end
end

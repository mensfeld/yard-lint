# frozen_string_literal: true

describe 'Documentation/OrphanedDocComment' do
  attr_reader :config, :tmpdir

  before do
    @tmpdir = Dir.mktmpdir
    @config = test_config do |c|
      c.set_validator_config('Documentation/OrphanedDocComment', 'Enabled', true)
    end
  end

  after do
    FileUtils.rm_rf(@tmpdir)
  end

  def write_file(content)
    path = File.join(@tmpdir, 'test.rb')
    File.write(path, content)
    path
  end

  def offenses_for(content)
    path = write_file(content)
    result = Yard::Lint.run(path: path, config: config, progress: false)
    result.offenses.select { |o| o[:name] == 'OrphanedDocComment' }
  end

  it 'is enabled by default' do
    default_config = test_config
    path = write_file(<<~RUBY)
      # @param x [Integer] something
      x = 1
      def foo(x); end
    RUBY
    result = Yard::Lint.run(path: path, config: default_config, progress: false)
    refute_empty(result.offenses.select { |o| o[:name] == 'OrphanedDocComment' })
  end

  it 'flags a comment with tags before a variable assignment' do
    offenses = offenses_for(<<~RUBY)
      # @param name [String] the name
      # @return [void]
      my_var = 'value'

      def real_method(name); end
    RUBY
    assert_equal(1, offenses.count)
    assert_includes(offenses.first[:message], '@param')
    assert_includes(offenses.first[:message], '@return')
    assert_equal(1, offenses.first[:location_line])
  end

  it 'flags a comment with tags before a require statement' do
    offenses = offenses_for(<<~RUBY)
      def documented_method; end

      # @param x [Integer] orphaned
      require 'ostruct'
    RUBY
    assert_equal(1, offenses.count)
    assert_includes(offenses.first[:message], '@param')
  end

  it 'flags a comment with tags before an include statement' do
    offenses = offenses_for(<<~RUBY)
      # @return [void] orphaned
      include Comparable

      def real_method; end
    RUBY
    assert_equal(1, offenses.count)
  end

  it 'flags a comment with tags before an extend statement' do
    offenses = offenses_for(<<~RUBY)
      # @return [void] orphaned
      extend Comparable

      def real_method; end
    RUBY
    assert_equal(1, offenses.count)
  end

  it 'flags a comment with tags at end of file' do
    offenses = offenses_for(<<~RUBY)
      def real_method; end

      # @param x [Integer] orphaned at EOF
      # @return [String] also orphaned
    RUBY
    assert_equal(1, offenses.count)
    assert_includes(offenses.first[:message], '@param')
  end

  it 'flags a comment with tags followed by blank lines then non-definition code' do
    offenses = offenses_for(<<~RUBY)
      # @param x [Integer] orphaned
      # @return [String]

      x = something

      def real_method(x); end
    RUBY
    assert_equal(1, offenses.count)
  end

  it 'does not flag a comment before a def' do
    offenses = offenses_for(<<~RUBY)
      # @param name [String] the name
      # @return [void]
      def process(name); end
    RUBY
    assert_empty(offenses)
  end

  it 'does not flag a comment before a class' do
    offenses = offenses_for(<<~RUBY)
      # @param name [String] something
      class MyClass
        def initialize(name); end
      end
    RUBY
    assert_empty(offenses)
  end

  it 'does not flag a comment before a module' do
    offenses = offenses_for(<<~RUBY)
      # @return [void]
      module MyModule
        def foo; end
      end
    RUBY
    assert_empty(offenses)
  end

  it 'does not flag a comment before attr_reader' do
    offenses = offenses_for(<<~RUBY)
      class MyClass
        # @return [String] the name
        attr_reader :name

        def initialize(name)
          @name = name
        end
      end
    RUBY
    assert_empty(offenses)
  end

  it 'does not flag a comment before private def' do
    offenses = offenses_for(<<~RUBY)
      class MyClass
        # @param x [Integer] something
        # @return [void]
        private def helper(x); end
      end
    RUBY
    assert_empty(offenses)
  end

  it 'does not flag a plain comment with no YARD tags before non-definition code' do
    offenses = offenses_for(<<~RUBY)
      # This is just a regular comment
      # with no YARD tags at all
      x = 1

      def real_method; end
    RUBY
    assert_empty(offenses)
  end

  it 'does not flag a YARD directive (@!macro) before non-definition code' do
    offenses = offenses_for(<<~RUBY)
      # @!macro my_macro
      #   @param $1 [String] the value
      x = 1

      def real_method(x); end
    RUBY
    assert_empty(offenses)
  end

  it 'does not trigger on frozen_string_literal magic comment' do
    offenses = offenses_for(<<~RUBY)
      # frozen_string_literal: true

      # @param name [String] something
      # @return [void]
      def process(name); end
    RUBY
    assert_empty(offenses)
  end

  it 'includes validator field in offenses' do
    offenses = offenses_for(<<~RUBY)
      # @param x [Integer] orphaned
      x = 1
      def foo(x); end
    RUBY
    assert_equal('Documentation/OrphanedDocComment', offenses.first[:validator])
  end

  it 'reports correct line number for the start of the comment block' do
    offenses = offenses_for(<<~RUBY)
      def real_method; end

      # @param x [Integer] the value
      # @return [void]
      x = 1
    RUBY
    assert_equal(1, offenses.count)
    assert_equal(3, offenses.first[:location_line])
  end

  it 'does not flag a comment before a constant assignment' do
    offenses = offenses_for(<<~RUBY)
      # @return [String] the default name
      DEFAULT_NAME = 'world'

      def real_method; end
    RUBY
    assert_empty(offenses)
  end

  it 'does not flag a comment before a Struct constant assignment' do
    offenses = offenses_for(<<~RUBY)
      # @param name [String] the name
      # @param age [Integer] the age
      Person = Struct.new(:name, :age)

      def real_method; end
    RUBY
    assert_empty(offenses)
  end

  it 'does not flag a comment before a Data.define constant assignment' do
    offenses = offenses_for(<<~RUBY)
      # @param x [Integer] the x coordinate
      # @param y [Integer] the y coordinate
      Point = Data.define(:x, :y)

      def real_method; end
    RUBY
    assert_empty(offenses)
  end

  it 'does not flag a comment before attr_writer' do
    offenses = offenses_for(<<~RUBY)
      class MyClass
        # @return [String]
        attr_writer :name

        def initialize(name)
          @name = name
        end
      end
    RUBY
    assert_empty(offenses)
  end

  it 'does not flag a comment before attr_accessor' do
    offenses = offenses_for(<<~RUBY)
      class MyClass
        # @return [String]
        attr_accessor :name

        def initialize(name)
          @name = name
        end
      end
    RUBY
    assert_empty(offenses)
  end

  it 'does not flag a comment before alias_method' do
    offenses = offenses_for(<<~RUBY)
      class MyClass
        def foo; end

        # @deprecated Use foo instead
        alias_method :bar, :foo
      end
    RUBY
    assert_empty(offenses)
  end

  it 'does not flag a comment before protected def' do
    offenses = offenses_for(<<~RUBY)
      class MyClass
        # @param x [Integer] something
        # @return [void]
        protected def helper(x); end
      end
    RUBY
    assert_empty(offenses)
  end

  it 'does not flag a comment before public def' do
    offenses = offenses_for(<<~RUBY)
      class MyClass
        # @param x [Integer] something
        # @return [void]
        public def helper(x); end
      end
    RUBY
    assert_empty(offenses)
  end

  it 'does not flag a comment before a class method definition' do
    offenses = offenses_for(<<~RUBY)
      class MyClass
        # @param name [String] the name
        # @return [void]
        def self.create(name); end
      end
    RUBY
    assert_empty(offenses)
  end

  it 'flags a comment before standalone protected (YARD drops it)' do
    offenses = offenses_for(<<~RUBY)
      class MyClass
        def public_method; end

        # @return [void] this gets orphaned
        protected

        def protected_method; end
      end
    RUBY
    assert_equal(1, offenses.count)
  end

  it 'flags a comment before standalone private keyword (YARD drops it)' do
    offenses = offenses_for(<<~RUBY)
      class MyClass
        def public_method; end

        # @return [void] this gets orphaned
        private

        def private_method; end
      end
    RUBY
    assert_equal(1, offenses.count)
  end

  it 'flags a comment before standalone public keyword (YARD drops it)' do
    offenses = offenses_for(<<~RUBY)
      class MyClass
        # @return [void] this gets orphaned
        public

        def my_method; end
      end
    RUBY
    assert_equal(1, offenses.count)
  end

  it 'flags a comment before extend self (YARD drops it)' do
    offenses = offenses_for(<<~RUBY)
      module MyModule
        # @return [void] this gets orphaned
        extend self

        def my_method; end
      end
    RUBY
    assert_equal(1, offenses.count)
  end

  it 'does not flag a comment before define_method (YARD documents it)' do
    offenses = offenses_for(<<~RUBY)
      class MyClass
        # @param value [Integer] the value
        # @return [void]
        define_method(:my_method) { |value| }
      end
    RUBY
    assert_empty(offenses)
  end

  it 'does not flag a comment before a multiline method definition' do
    offenses = offenses_for(<<~RUBY)
      # @param name [String] the name
      # @param age [Integer] the age
      # @return [void]
      def create(
        name,
        age
      ); end
    RUBY
    assert_empty(offenses)
  end

  it 'detects multiple orphaned comment blocks in one file' do
    offenses = offenses_for(<<~RUBY)
      # @param x [Integer] first orphan
      x = 1

      def real_method(x); end

      # @return [String] second orphan
      y = 2

      def another_method; end
    RUBY
    assert_equal(2, offenses.count)
  end
end

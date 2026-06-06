# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

describe 'Tags/MissingYield' do
  attr_reader :test_dir

  before do
    @test_dir = Dir.mktmpdir
  end

  after do
    FileUtils.rm_rf(@test_dir) if @test_dir && File.exist?(@test_dir)
  end

  def create_test_file(filename, content)
    path = File.join(@test_dir, filename)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
    path
  end

  def enabled_config
    Yard::Lint::Config.new do |c|
      c.set_validator_config('Tags/MissingYield', 'Enabled', true)
    end
  end

  def missing_yield_offenses(result)
    result.offenses.select { |o| o[:name].to_s == 'MissingYield' }
  end

  # -- Opt-in behaviour --

  it 'is disabled by default and reports no offenses without opt-in' do
    config = Yard::Lint::Config.new
    file = create_test_file('example.rb', <<~RUBY)
      class Foo
        # @param items [Array] items
        def each(items)
          items.each { |item| yield item }
        end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: config, progress: false)
    assert_empty(missing_yield_offenses(result), 'should be disabled by default')
  end

  # -- Core detection --

  it 'flags a method that yields with no yield-related tag' do
    file = create_test_file('example.rb', <<~RUBY)
      class Foo
        # Iterates over items.
        # @param items [Array] the items
        def each(items)
          items.each { |item| yield item }
        end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: enabled_config, progress: false)
    offenses = missing_yield_offenses(result)
    refute_empty(offenses, 'method with yield and no @yield tag should be flagged')
    assert_includes(offenses.first[:message], 'each')
  end

  it 'does not flag a method that yields when @yield tag is present' do
    file = create_test_file('example.rb', <<~RUBY)
      class Foo
        # Iterates over items.
        # @param items [Array] the items
        # @yield [item] each item
        def each(items)
          items.each { |item| yield item }
        end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: enabled_config, progress: false)
    assert_empty(missing_yield_offenses(result))
  end

  it 'does not flag a method when only @yieldparam is present' do
    file = create_test_file('example.rb', <<~RUBY)
      class Foo
        # @param items [Array] the items
        # @yieldparam item [Object] each item yielded
        def each(items)
          items.each { |item| yield item }
        end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: enabled_config, progress: false)
    assert_empty(missing_yield_offenses(result))
  end

  it 'does not flag a method when only @yieldreturn is present' do
    file = create_test_file('example.rb', <<~RUBY)
      class Foo
        # @param items [Array] the items
        # @yieldreturn [void]
        def each(items)
          items.each { |item| yield item }
        end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: enabled_config, progress: false)
    assert_empty(missing_yield_offenses(result))
  end

  it 'does not flag a method that has no yield at all' do
    file = create_test_file('example.rb', <<~RUBY)
      class Foo
        # @param x [Integer] a number
        # @return [Integer] doubled value
        def double(x)
          x * 2
        end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: enabled_config, progress: false)
    assert_empty(missing_yield_offenses(result))
  end

  # -- yield keyword variants --

  it 'flags yield with arguments (yield value)' do
    file = create_test_file('example.rb', <<~RUBY)
      class Foo
        # @param value [String] value
        def wrap(value)
          yield value
        end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: enabled_config, progress: false)
    refute_empty(missing_yield_offenses(result))
  end

  it 'flags yield self' do
    file = create_test_file('example.rb', <<~RUBY)
      class Foo
        # Taps self into a block.
        def tap_self
          yield self
          self
        end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: enabled_config, progress: false)
    refute_empty(missing_yield_offenses(result))
  end

  it 'flags return yield pattern' do
    file = create_test_file('example.rb', <<~RUBY)
      class Foo
        # Delegates to block.
        def delegate
          return yield
        end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: enabled_config, progress: false)
    refute_empty(missing_yield_offenses(result))
  end

  it 'flags conditional yield with block_given?' do
    file = create_test_file('example.rb', <<~RUBY)
      class Foo
        # Optionally yields.
        def maybe_yield(val)
          yield val if block_given?
        end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: enabled_config, progress: false)
    refute_empty(missing_yield_offenses(result))
  end

  # -- False positive guards --

  it 'does not flag yield inside a comment line' do
    file = create_test_file('example.rb', <<~RUBY)
      class Foo
        # This method does not yield - use yield in the caller instead.
        # @return [String] result
        def process
          "done"
        end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: enabled_config, progress: false)
    assert_empty(missing_yield_offenses(result))
  end

  it 'does not flag yield inside a double-quoted string literal' do
    file = create_test_file('example.rb', <<~RUBY)
      class Foo
        # @return [String] a message
        def message
          "please yield a block to this method"
        end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: enabled_config, progress: false)
    assert_empty(missing_yield_offenses(result))
  end

  it 'does not flag yield inside a single-quoted string literal' do
    file = create_test_file('example.rb', <<~RUBY)
      class Foo
        # @return [String] a message
        def message
          'please yield a block'
        end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: enabled_config, progress: false)
    assert_empty(missing_yield_offenses(result))
  end

  it 'does not flag Fiber.yield (method call, not keyword)' do
    file = create_test_file('example.rb', <<~RUBY)
      class Foo
        # @return [Object] fiber result
        def run_fiber
          Fiber.yield(42)
        end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: enabled_config, progress: false)
    assert_empty(missing_yield_offenses(result))
  end

  it 'does not flag yielder.yield (Enumerator::Yielder method call)' do
    file = create_test_file('example.rb', <<~RUBY)
      class Foo
        # @return [Enumerator] lazy enumerator
        def lazy_each
          Enumerator.new do |y|
            @items.each { |item| y.yield(item) }
          end
        end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: enabled_config, progress: false)
    assert_empty(missing_yield_offenses(result))
  end

  it 'does not flag a method named yield_something (not the yield keyword)' do
    file = create_test_file('example.rb', <<~RUBY)
      class Foo
        # @return [void]
        def yield_control
          :noop
        end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: enabled_config, progress: false)
    assert_empty(missing_yield_offenses(result))
  end

  # -- Visibility --

  it 'flags private methods that yield' do
    file = create_test_file('example.rb', <<~RUBY)
      class Foo
        private

        # Helper that yields to a block.
        def internal_each(items)
          items.each { |i| yield i }
        end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: enabled_config, progress: false)
    refute_empty(missing_yield_offenses(result))
  end

  # -- Alias / implicit method skip --

  it 'does not flag alias methods' do
    file = create_test_file('example.rb', <<~RUBY)
      class Foo
        # Iterates.
        # @yield [item] each item
        def each
          yield 1
        end

        alias each_item each
      end
    RUBY

    result = Yard::Lint.run(path: file, config: enabled_config, progress: false)
    # only `each` is flagged - `each_item` is an alias and should not be
    # (each itself is documented so neither should be flagged)
    assert_empty(missing_yield_offenses(result))
  end

  # -- Multiple methods --

  it 'flags all methods missing @yield across multiple methods in a file' do
    file = create_test_file('example.rb', <<~RUBY)
      class Foo
        # Processes items.
        def process(items)
          items.each { |i| yield i }
        end

        # Wraps a value.
        def wrap(val)
          yield val
        end

        # Already documented.
        # @yield [x] the value
        def documented(val)
          yield val
        end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: enabled_config, progress: false)
    offenses = missing_yield_offenses(result)
    assert_equal(2, offenses.size,
      "Expected 2 offenses but got #{offenses.size}: #{offenses.map { |o| o[:message] }}")
    messages = offenses.map { |o| o[:message] }
    assert(messages.any? { |m| m.include?('process') })
    assert(messages.any? { |m| m.include?('wrap') })
  end
end

# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

describe 'Tags/OverloadConsistency' do
  attr_reader :dir

  before { @dir = Dir.mktmpdir }
  after { FileUtils.rm_rf(dir) }

  # Lint the given source and return only this validator's offenses.
  # @param source [String] Ruby source to lint
  # @return [Array<Hash>] offenses produced by Tags/OverloadConsistency
  def offenses_for(source)
    path = File.join(dir, 'example.rb')
    File.write(path, source)

    Yard::Lint
      .run(path: path, config: test_config, progress: false)
      .offenses
      .select { |offense| offense[:validator] == 'Tags/OverloadConsistency' }
  end

  # @param source [String] Ruby source to lint
  # @return [Array<String>] offense messages
  def messages_for(source)
    offenses_for(source).map { |offense| offense[:message] }
  end

  it 'flags a @param that is not in the overload signature' do
    offenses = offenses_for(<<~RUBY)
      # Store
      class OverloadStore
        # Fetches a value
        # @overload fetch(key)
        #   @param name [String] the key
        #   @return [Object]
        def fetch(*args); end
      end
    RUBY

    assert_equal(
      [
        "Overload 'fetch(key)' documents @param 'name', which is not in its signature",
        "Overload 'fetch(key)' has no @param for 'key'"
      ],
      offenses.map { |offense| offense[:message] }
    )
    assert_equal([7, 7], offenses.map { |offense| offense[:location_line] })
    assert_equal(['warning'], offenses.map { |offense| offense[:severity] }.uniq)
  end

  it 'checks each overload against its own signature, not the pooled tags' do
    messages = messages_for(<<~RUBY)
      # Store
      class OverloadStore
        # Fetches a value
        # @overload fetch(key)
        #   @param key [String] the key
        #   @param default [Object] fallback
        #   @return [Object]
        # @overload fetch(key, default)
        #   @param key [String] the key
        #   @return [Object]
        def fetch(*args); end
      end
    RUBY

    assert_equal(
      [
        "Overload 'fetch(key)' documents @param 'default', which is not in its signature",
        "Overload 'fetch(key, default)' has no @param for 'default'"
      ],
      messages
    )
  end

  it 'accepts overloads whose tags match their signatures' do
    messages = messages_for(<<~RUBY)
      # Store
      class OverloadStore
        # Fetches a value
        # @overload fetch(key)
        #   @param key [String] the key
        #   @return [Object]
        # @overload fetch(key, default)
        #   @param key [String] the key
        #   @param default [Object] fallback
        #   @return [Object]
        def fetch(*args); end
      end
    RUBY

    assert_equal([], messages)
  end

  it 'does not require @param in an overload that documents no parameter' do
    messages = messages_for(<<~RUBY)
      # Store
      class OverloadStore
        # Fetches a value
        # @overload fetch(key)
        # @overload fetch(key, default)
        #   Uses the default when the key is missing
        def fetch(*args); end
      end
    RUBY

    assert_equal([], messages)
  end

  it 'matches splat, keyword and block parameters by their bare names' do
    messages = messages_for(<<~RUBY)
      # Runner
      class OverloadRunner
        # Runs
        # @overload run(name, *rest, timeout: 1, **opts, &block)
        #   @param name [String] job name
        #   @param timeout [Integer] seconds
        #   @param opts [Hash] options
        #   @param block [Proc] callback
        #   @param rest [Array] extra arguments
        #   @return [void]
        def run(*args, **kwargs, &block); end
      end
    RUBY

    assert_equal([], messages)
  end

  it 'does not require @param for splat and block parameters' do
    messages = messages_for(<<~RUBY)
      # Runner
      class OverloadRunner
        # Runs
        # @overload run(name, *rest, timeout:, **opts, &block)
        #   @param name [String] job name
        #   @return [void]
        def run(*args, **kwargs, &block); end
      end
    RUBY

    assert_equal(["Overload 'run(name, *rest, timeout:, **opts, &block)' has no @param for 'timeout'"], messages)
  end

  it 'does not check names against forwarded or anonymous parameters' do
    messages = messages_for(<<~RUBY)
      # Runner
      class OverloadRunner
        # Runs
        # @overload run(...)
        #   @param name [String] job name
        # @overload run(job, *, **)
        #   @param job [Object] job
        #   @param options [Hash] options
        def run(...); end
      end
    RUBY

    assert_equal([], messages)
  end

  it 'flags an overload without @return when another overload has one' do
    messages = messages_for(<<~RUBY)
      # Store
      class OverloadStore
        # Fetches a value
        # @overload fetch(key)
        #   @return [Object]
        # @overload fetch(key, &block)
        #   @yield [key] when the key is missing
        def fetch(*args); end
      end
    RUBY

    assert_equal(["Overload 'fetch(key, &block)' has no @return, while other overloads of this method have one"], messages)
  end

  it 'accepts overloads without @return when the method docstring has one' do
    messages = messages_for(<<~RUBY)
      # Store
      class OverloadStore
        # Fetches a value
        # @overload fetch(key)
        #   @return [String]
        # @overload fetch(key, default)
        # @return [Object]
        def fetch(*args); end
      end
    RUBY

    assert_equal([], messages)
  end

  it 'checks private methods' do
    messages = messages_for(<<~RUBY)
      # Store
      class OverloadStore
        private

        # Fetches a value
        # @overload fetch(key)
        #   @param name [String] the key
        def fetch(*args); end
      end
    RUBY

    assert_equal(
      [
        "Overload 'fetch(key)' documents @param 'name', which is not in its signature",
        "Overload 'fetch(key)' has no @param for 'key'"
      ],
      messages
    )
  end

  it 'reports a module_function method once' do
    messages = messages_for(<<~RUBY)
      # Helpers
      module OverloadHelpers
        module_function

        # Fetches a value
        # @overload fetch(key)
        #   @param name [String] the key
        #   @param key [String] the key
        def fetch(*args); end
      end
    RUBY

    assert_equal(["Overload 'fetch(key)' documents @param 'name', which is not in its signature"], messages)
  end

  it 'handles methods defined on a constant' do
    messages = messages_for(<<~RUBY)
      ANY = Object.new

      # Compares
      # @overload ==(other)
      #   @param others [Object] value
      def ANY.==(other); end

      # Compares
      # @overload ===(other)
      def ANY.===(other); end
    RUBY

    assert_equal(
      [
        "Overload '==(other)' documents @param 'others', which is not in its signature",
        "Overload '==(other)' has no @param for 'other'"
      ],
      messages
    )
  end
end

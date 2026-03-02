# frozen_string_literal: true

require 'test_helper'

require 'tmpdir'
require 'fileutils'

describe 'Missing Return' do
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
    @enabled_config ||= Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/MissingReturn', 'Enabled', true)
      end
  end

  it 'when validator is disabled by default does not report missing return tags' do
    config = Yard::Lint::Config.new

    file = create_test_file('example.rb', <<~RUBY)
      # Example class
      class Example
        # Method without return tag
        def calculate
          42
          end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: config)
    missing_return_offenses = result.offenses.select do |o|
      o[:name].to_s == 'MissingReturnTag'
      end
    assert_empty(missing_return_offenses,
      'Validator should be disabled by default')
  end

  it 'methods with return tag does not report methods that have return tags' do
    file = create_test_file('with_return.rb', <<~RUBY)
      # Calculator class
      class Calculator
        # Adds two numbers
        # @param a [Integer] first number
        # @param b [Integer] second number
        # @return [Integer] the sum
        def add(a, b)
          a + b
          end
        # Gets current value
        # @return [Integer] current value
        def current_value
          @value
          end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: enabled_config)
    missing_return_offenses = result.offenses.select do |o|
      o[:name].to_s == 'MissingReturnTag'
      end
    assert_empty(missing_return_offenses,
      'Methods with @return tags should not be flagged')
  end

  it 'methods without return tag reports methods missing return tags' do
    file = create_test_file('no_return.rb', <<~RUBY)
      # Calculator class
      class Calculator
        # Multiplies two numbers
        # @param a [Integer] first number
        # @param b [Integer] second number
        def multiply(a, b)
          a * b
          end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: enabled_config)
    missing_return_offenses = result.offenses.select do |o|
      o[:name].to_s == 'MissingReturnTag' && o[:message].include?('multiply')
      end
    refute_empty(missing_return_offenses,
      'Method without @return tag should be flagged')

    offense = missing_return_offenses.first
    assert_includes(offense[:message], 'Missing @return tag for `Calculator#multiply`')
  end

  it 'initialize methods does not report initialize methods' do
    file = create_test_file('init.rb', <<~RUBY)
      # Example class
      class Example
        # Constructor
        # @param value [Integer] initial value
        def initialize(value)
          @value = value
          end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: enabled_config)
    missing_return_offenses = result.offenses.select do |o|
      o[:name].to_s == 'MissingReturnTag' && o[:message].include?('initialize')
      end
    assert_empty(missing_return_offenses,
      'Initialize methods should be excluded by default')
  end

  it 'boolean methods does not report boolean methods' do
    file = create_test_file('boolean.rb', <<~RUBY)
      # Checker class
      class Checker
        # Checks if valid
        def valid?
          true
          end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: enabled_config)
    missing_return_offenses = result.offenses.select do |o|
      o[:name].to_s == 'MissingReturnTag' && o[:message].include?('valid?')
      end
    assert_empty(missing_return_offenses,
      'Boolean methods have @return added automatically by YARD')
  end

  it 'custom exclusions excludes methods matching regex pattern' do
    config_with_exclusions = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/MissingReturn', 'Enabled', true)
      c.set_validator_config('Documentation/MissingReturn',
        'ExcludedMethods',
        ['initialize', '/^_/']
      )
    end

    file = create_test_file('private_methods.rb', <<~RUBY)
      # Example class
      class Example
        # Private helper method
        def _helper
          :private
          end
        # Public method
        def public_method
          :public
          end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: config_with_exclusions)

    # _helper should not be flagged (excluded by regex)
    helper_offenses = result.offenses.select do |o|
      o[:name].to_s == 'MissingReturnTag' && o[:message].include?('_helper')
      end
    assert_empty(helper_offenses,
      'Methods matching /^_/ should be excluded')

    # public_method should be flagged
    public_offenses = result.offenses.select do |o|
      o[:name].to_s == 'MissingReturnTag' && o[:message].include?('public_method')
      end
    refute_empty(public_offenses,
      'Public method without @return should be flagged')
  end

  it 'custom exclusions excludes methods matching arity pattern' do
    config_with_arity = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/MissingReturn', 'Enabled', true)
      c.set_validator_config('Documentation/MissingReturn',
        'ExcludedMethods',
        ['initialize', 'fetch/1']
      )
    end

    file = create_test_file('arity_test.rb', <<~RUBY)
      # Cache class
      class Cache
        # Fetch with key (1 param - should be excluded)
        # @param key [String] the cache key
        def fetch(key)
          @cache[key]
          end
        # Fetch with key and default (2 params - should NOT be excluded)
        # @param key [String] the cache key
        # @param default [Object] default value
        def fetch(key, default)
          @cache.fetch(key, default)
          end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: config_with_arity)

    # Only the last fetch definition (fetch/2) is visible to YARD here,
    # so only that method can be evaluated and potentially flagged
    fetch_offenses = result.offenses.select do |o|
      o[:name].to_s == 'MissingReturnTag' && o[:message].include?('fetch')
      end
    # The fetch/2 should be flagged; fetch/1 would be excluded if it existed separately
    # In Ruby, the second definition overwrites the first
    assert_equal(1, fetch_offenses.count,
      'Only the 2-parameter fetch should be flagged')
  end

  it 'comprehensive handles mixed scenarios correctly' do
    file = create_test_file('comprehensive.rb', <<~RUBY)
      # Comprehensive test class
      class ComprehensiveTest
        # Constructor - excluded by default
        def initialize
          @value = 0
          end
        # Has @return - should pass
        # @return [Integer] the value
        def with_return
          @value
          end
        # Missing @return - should fail
        def without_return
          @value * 2
          end
        # Boolean with @return - should pass
        # @return [Boolean] whether valid
        def valid?
          true
          end
        # Boolean without explicit @return - YARD adds it automatically so won't fail
        def enabled?
          false
          end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: enabled_config)
    missing_return_offenses = result.offenses.select do |o|
      o[:name].to_s == 'MissingReturnTag'
      end
    # Should flag: without_return
    # Should NOT flag: initialize (excluded), with_return (has @return),
    #                  valid? (has @return), enabled? (YARD adds @return automatically)
    assert_equal(1, missing_return_offenses.count,
      "Expected 1 offense but got #{missing_return_offenses.count}: " \
      "#{missing_return_offenses.map { |o| o[:message] }.join(', ')}")

    flagged_methods = missing_return_offenses.map { |o| o[:message] }
    flagged_methods.each { |e| assert_match(/without_return/, e) }
  end
end


# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

RSpec.describe 'MissingReturn validator', :cache_isolation do
  let(:test_dir) { Dir.mktmpdir }

  after { FileUtils.rm_rf(test_dir) if test_dir && File.exist?(test_dir) }

  def create_test_file(filename, content)
    path = File.join(test_dir, filename)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
    path
  end

  describe 'when validator is disabled by default' do
    it 'does not report missing @return tags' do
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

      expect(missing_return_offenses).to be_empty,
        'Validator should be disabled by default'
    end
  end

  describe 'when validator is enabled' do
    let(:config) do
      Yard::Lint::Config.new do |c|
        c.send(:set_validator_config, 'Documentation/MissingReturn', 'Enabled', true)
      end
    end

    context 'methods with @return tag' do
      it 'does not report methods that have @return tags' do
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

        result = Yard::Lint.run(path: file, config: config)
        missing_return_offenses = result.offenses.select do |o|
          o[:name].to_s == 'MissingReturnTag'
        end

        expect(missing_return_offenses).to be_empty,
          'Methods with @return tags should not be flagged'
      end
    end

    context 'methods without @return tag' do
      it 'reports methods missing @return tags' do
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

        result = Yard::Lint.run(path: file, config: config)
        missing_return_offenses = result.offenses.select do |o|
          o[:name].to_s == 'MissingReturnTag' && o[:message].include?('multiply')
        end

        expect(missing_return_offenses).not_to be_empty,
          'Method without @return tag should be flagged'

        offense = missing_return_offenses.first
        expect(offense[:message]).to include('Missing @return tag for `Calculator#multiply`')
      end
    end

    context 'initialize methods' do
      it 'does not report initialize methods (excluded by default)' do
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

        result = Yard::Lint.run(path: file, config: config)
        missing_return_offenses = result.offenses.select do |o|
          o[:name].to_s == 'MissingReturnTag' && o[:message].include?('initialize')
        end

        expect(missing_return_offenses).to be_empty,
          'Initialize methods should be excluded by default'
      end
    end

    context 'boolean methods' do
      it 'does not report boolean methods (YARD adds @return automatically)' do
        file = create_test_file('boolean.rb', <<~RUBY)
          # Checker class
          class Checker
            # Checks if valid
            def valid?
              true
            end
          end
        RUBY

        result = Yard::Lint.run(path: file, config: config)
        missing_return_offenses = result.offenses.select do |o|
          o[:name].to_s == 'MissingReturnTag' && o[:message].include?('valid?')
        end

        expect(missing_return_offenses).to be_empty,
          'Boolean methods have @return added automatically by YARD'
      end
    end

    context 'with custom exclusions' do
      it 'excludes methods matching regex pattern' do
        config_with_exclusions = Yard::Lint::Config.new do |c|
          c.send(:set_validator_config, 'Documentation/MissingReturn', 'Enabled', true)
          c.send(
            :set_validator_config,
            'Documentation/MissingReturn',
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
        expect(helper_offenses).to be_empty,
          'Methods matching /^_/ should be excluded'

        # public_method should be flagged
        public_offenses = result.offenses.select do |o|
          o[:name].to_s == 'MissingReturnTag' && o[:message].include?('public_method')
        end
        expect(public_offenses).not_to be_empty,
          'Public method without @return should be flagged'
      end

      it 'excludes methods matching arity pattern' do
        config_with_arity = Yard::Lint::Config.new do |c|
          c.send(:set_validator_config, 'Documentation/MissingReturn', 'Enabled', true)
          c.send(
            :set_validator_config,
            'Documentation/MissingReturn',
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

        # Both fetch methods should not be flagged because YARD will only see
        # the last definition in this case
        fetch_offenses = result.offenses.select do |o|
          o[:name].to_s == 'MissingReturnTag' && o[:message].include?('fetch')
        end

        # The fetch/2 should be flagged, fetch/1 would be if it existed separately
        # In Ruby, the second definition overwrites the first
        expect(fetch_offenses.count).to eq(1),
          'Only the 2-parameter fetch should be flagged'
      end
    end

    context 'comprehensive test' do
      it 'handles mixed scenarios correctly' do
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

        result = Yard::Lint.run(path: file, config: config)
        missing_return_offenses = result.offenses.select do |o|
          o[:name].to_s == 'MissingReturnTag'
        end

        # Should flag: without_return
        # Should NOT flag: initialize (excluded), with_return (has @return),
        #                  valid? (has @return), enabled? (YARD adds @return automatically)
        expect(missing_return_offenses.count).to eq(1),
          "Expected 1 offense but got #{missing_return_offenses.count}: " \
          "#{missing_return_offenses.map { |o| o[:message] }.join(', ')}"

        flagged_methods = missing_return_offenses.map { |o| o[:message] }
        expect(flagged_methods).to all(match(/without_return/))
      end
    end
  end
end

# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

RSpec.describe 'Boolean methods with @return tags', :cache_isolation do
  let(:config) do
    Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects', 'Enabled', true)
      c.send(:set_validator_config, 'Documentation/UndocumentedBooleanMethods', 'Enabled', true)
    end
  end

  let(:test_dir) { Dir.mktmpdir }

  after { FileUtils.rm_rf(test_dir) if test_dir && File.exist?(test_dir) }

  def create_test_file(filename, content)
    path = File.join(test_dir, filename)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
    path
  end

  describe 'boolean methods with complete documentation' do
    context 'when method has comment and @return [Boolean] tag' do
      it 'does not report method as undocumented (class is undocumented)' do
        file = create_test_file('markable.rb', <<~RUBY)
          # VirtualOffsetManager manages virtual offsets
          class VirtualOffsetManager
            # Is there a real offset we can mark as consumed
            # @return [Boolean]
            def markable?
              !@real_offset.negative?
            end
          end
        RUBY

        result = Yard::Lint.run(path: file, config: config)
        undocumented = result.offenses.select { |o| o[:name].to_s == 'UndocumentedObject' }

        # The method has full documentation and should NOT be flagged
        method_offenses = undocumented.select { |o| o[:message].include?('markable?') }
        expect(method_offenses).to be_empty,
          "Expected markable? method not to be flagged, but got: #{method_offenses.inspect}"
      end
    end

    context 'when method has only @return [Boolean] tag without description' do
      it 'does not report method as undocumented' do
        file = create_test_file('success.rb', <<~RUBY)
          # Result class
          class Result
            # @return [Boolean]
            def success?
              @success
            end
          end
        RUBY

        result = Yard::Lint.run(path: file, config: config)
        undocumented = result.offenses.select { |o| o[:name].to_s == 'UndocumentedObject' }

        # The method has @return tag and should NOT be flagged
        method_offenses = undocumented.select { |o| o[:message].include?('success?') }
        expect(method_offenses).to be_empty,
          "Expected success? method not to be flagged, but got: #{method_offenses.inspect}"
      end
    end

    context 'when method has description and @return with parameters' do
      it 'does not report method as undocumented' do
        file = create_test_file('respond_to.rb', <<~RUBY)
          # Proxy class
          class Proxy
            # Tells whether or not a given element exists on the target
            # @param method_name [Symbol] name of the missing method
            # @param include_private [Boolean] should we include private in the check as well
            # @return [Boolean]
            def respond_to_missing?(method_name, include_private = false)
              true
            end
          end
        RUBY

        result = Yard::Lint.run(path: file, config: config)
        undocumented = result.offenses.select { |o| o[:name].to_s == 'UndocumentedObject' }

        # The method has full documentation and should NOT be flagged
        method_offenses = undocumented.select do |o|
          o[:message].include?('respond_to_missing?')
        end
        expect(method_offenses).to be_empty,
          "Expected respond_to_missing? not to be flagged, got: #{method_offenses.inspect}"
      end
    end

    context 'when boolean method has multi-line description' do
      it 'does not report method as undocumented' do
        file = create_test_file('supervised.rb', <<~RUBY)
          # Process class
          class Process
            # Checks if the process is currently being supervised
            # by an external process manager
            # @return [Boolean] true if supervised, false otherwise
            def supervised?
              @supervised
            end
          end
        RUBY

        result = Yard::Lint.run(path: file, config: config)
        undocumented = result.offenses.select { |o| o[:name].to_s == 'UndocumentedObject' }

        # The method has full documentation and should NOT be flagged
        method_offenses = undocumented.select { |o| o[:message].include?('supervised?') }
        expect(method_offenses).to be_empty,
          "Expected supervised? method not to be flagged, but got: #{method_offenses.inspect}"
      end
    end
  end

  describe 'boolean methods with incomplete documentation' do
    context 'when method has no documentation at all' do
      it 'reports as undocumented' do
        file = create_test_file('no_docs.rb', <<~RUBY)
          # Example class
          class Example
            def valid?
              @valid
            end
          end
        RUBY

        result = Yard::Lint.run(path: file, config: config)
        undocumented = result.offenses.select { |o| o[:name].to_s == 'UndocumentedObject' }

        # Method without any documentation should be flagged
        method_offenses = undocumented.select { |o| o[:message].include?('valid?') }
        expect(method_offenses).not_to be_empty,
          'Expected valid? method to be flagged as undocumented'
      end
    end

    context 'when method has comment but no explicit @return tag' do
      it 'does not report as undocumented (YARD auto-infers @return for boolean methods)' do
        file = create_test_file('no_return.rb', <<~RUBY)
          # Example class
          class Example
            # Checks if valid
            def valid?
              @valid
            end
          end
        RUBY

        result = Yard::Lint.run(path: file, config: config)

        # With a comment, the method should NOT be flagged as undocumented
        # (it has docstring text, even without explicit @return tag)
        undocumented = result.offenses.select do |o|
          o[:name].to_s == 'UndocumentedObject' && o[:message].include?('valid?')
        end

        expect(undocumented).to be_empty,
          'Method with comment should not be flagged as undocumented'
      end
    end
  end

  describe 'edge cases from Karafka project' do
    it 'handles all Karafka examples correctly' do
      file = create_test_file('karafka_examples.rb', <<~RUBY)
        # Karafka module
        module Karafka
          module Helpers
            # MultiDelegator class
            class MultiDelegator
              # Delegates to target
              # @param method_name [Symbol] method to delegate
              # @return [Object] result from target
              def to(method_name)
                nil
              end
            end
          end

          module Pro
            module Processing
              module Coordinators
                # VirtualOffsetManager class
                class VirtualOffsetManager
                  # Is there a real offset we can mark as consumed
                  # @return [Boolean]
                  def markable?
                    true
                  end
                end
              end
            end
          end

          # Process class
          class Process
            # @return [Boolean]
            def supervised?
              true
            end
          end

          module Processing
            # Coordinator class
            class Coordinator
              # @return [Boolean]
              def success?
                true
              end
            end

            # Result class
            class Result
              # @return [Boolean]
              def success?
                true
              end
            end
          end

          module Routing
            # Proxy class
            class Proxy
              # Tells whether or not a given element exists on the target
              # @param method_name [Symbol] name of the missing method
              # @param include_private [Boolean] should we include private in the check as well
              # @return [Boolean]
              def respond_to_missing?(method_name, include_private = false)
                true
              end
            end
          end
        end
      RUBY

      result = Yard::Lint.run(path: file, config: config)

      # All boolean methods (markable?, supervised?, success?, respond_to_missing?)
      # have @return [Boolean] tags and should NOT be flagged as undocumented
      boolean_method_offenses = result.offenses.select do |o|
        o[:name].to_s == 'UndocumentedObject' &&
          (o[:message].include?('markable?') ||
           o[:message].include?('supervised?') ||
           o[:message].include?('success?') ||
           o[:message].include?('respond_to_missing?'))
      end

      messages = boolean_method_offenses.map { |o| o[:message] }.join(', ')
      expect(boolean_method_offenses).to be_empty,
        "Boolean methods with @return tags should not be flagged. Found: #{messages}"

      # The `to` method now has proper documentation, so it should NOT be flagged
      to_method_offenses = result.offenses.select do |o|
        o[:name].to_s == 'UndocumentedObject' && o[:message].include?('#to')
      end

      expect(to_method_offenses).to be_empty,
        "Method 'to' with complete docs should not be flagged"
    end
  end
end

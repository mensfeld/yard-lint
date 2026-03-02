# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

describe 'Boolean Methods With Return Tags' do
  attr_reader :config

  before do
    @config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects', 'Enabled', true)
      c.set_validator_config('Documentation/UndocumentedBooleanMethods', 'Enabled', true)
    end
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

  it 'complete documentation with comment and return boolean tag does not report' do
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
    assert_empty(method_offenses,
      "Expected markable? method not to be flagged, but got: #{method_offenses.inspect}")
  end

  it 'only return boolean tag without description does not report' do
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
    assert_empty(method_offenses,
      "Expected success? method not to be flagged, but got: #{method_offenses.inspect}")
  end

  it 'description and return with parameters does not report' do
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
    assert_empty(method_offenses,
      "Expected respond_to_missing? not to be flagged, got: #{method_offenses.inspect}")
  end

  it 'multi line description does not report' do
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
    assert_empty(method_offenses,
      "Expected supervised? method not to be flagged, but got: #{method_offenses.inspect}")
  end

  it 'no documentation at all reports as undocumented' do
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
    refute_empty(method_offenses,
      'Expected valid? method to be flagged as undocumented')
  end

  it 'comment but no explicit return tag does not report' do
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
    assert_empty(undocumented,
      'Method with comment should not be flagged as undocumented')
  end

  it 'karafka examples handles all correctly' do
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
    assert_empty(boolean_method_offenses,
      "Boolean methods with @return tags should not be flagged. Found: #{messages}")

    # The `to` method now has proper documentation, so it should NOT be flagged
    to_method_offenses = result.offenses.select do |o|
      o[:name].to_s == 'UndocumentedObject' && o[:message].include?('#to')
    end

    assert_empty(to_method_offenses,
      "Method 'to' with complete docs should not be flagged")
  end
end


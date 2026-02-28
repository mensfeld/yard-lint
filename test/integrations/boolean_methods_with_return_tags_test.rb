# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'test_helper'

class BooleanMethodsWithReturnTagsTest < Minitest::Test
  attr_reader :config, :test_dir

  def setup
    @config = Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Documentation/UndocumentedObjects', 'Enabled', true)
      c.send(:set_validator_config, 'Documentation/UndocumentedBooleanMethods', 'Enabled', true)
    end
    @test_dir = Dir.mktmpdir
  end

  def teardown
    FileUtils.rm_rf(@test_dir) if @test_dir && File.exist?(@test_dir)
  end

  def create_test_file(filename, content)
    path = File.join(@test_dir, filename)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
    path
  end

  def test_complete_documentation_with_comment_and_return_boolean_tag_does_not_report
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

  def test_only_return_boolean_tag_without_description_does_not_report
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

  def test_description_and_return_with_parameters_does_not_report
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

  def test_multi_line_description_does_not_report
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

  def test_no_documentation_at_all_reports_as_undocumented
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

  def test_comment_but_no_explicit_return_tag_does_not_report
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

  def test_karafka_examples_handles_all_correctly
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

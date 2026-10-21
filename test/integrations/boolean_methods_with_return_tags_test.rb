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

  it 'comment but no explicit return tag reports with the file and line' do
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

    offenses = result.offenses.select do |o|
      o[:name].to_s == 'UndocumentedObject' && o[:message].include?('valid?')
    end
    assert_equal(1, offenses.size)
    assert_equal(file, offenses.first[:location])
    assert_equal(4, offenses.first[:location_line])
    assert_includes(offenses.first[:message], '`Example#valid?`')
  end

  it 'no documentation at all reports once' do
    file = create_test_file('bare.rb', <<~RUBY)
      # Example class
      class Example
        def valid?
          @valid
        end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: config)

    offenses = result.offenses.select { |o| o[:message].include?('valid?') }
    assert_equal(1, offenses.size)
  end

  it 'class method without return tag reports with its title' do
    file = create_test_file('class_method.rb', <<~RUBY)
      # Example class
      class Example
        # Checks if enabled
        def self.enabled?
          true
        end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: config)

    offenses = result.offenses.select { |o| o[:message].include?('enabled?') }
    assert_equal(1, offenses.size)
    assert_equal(4, offenses.first[:location_line])
    assert_includes(offenses.first[:message], '`Example.enabled?`')
  end

  it 'root level method without return tag reports with its title' do
    file = create_test_file('root_method.rb', <<~RUBY)
      # Checks if enabled
      def enabled?
        true
      end
    RUBY

    result = Yard::Lint.run(path: file, config: config)

    offenses = result.offenses.select { |o| o[:message].include?('enabled?') }
    assert_equal(1, offenses.size)
    assert_equal(file, offenses.first[:location])
    assert_equal(2, offenses.first[:location_line])
    assert_includes(offenses.first[:message], '`#enabled?`')
  end

  it 'root level class method without return tag reports with its title' do
    file = create_test_file('root_class_method.rb', <<~RUBY)
      # Checks if enabled
      def self.enabled?
        true
      end
    RUBY

    result = Yard::Lint.run(path: file, config: config)

    offenses = result.offenses.select { |o| o[:message].include?('enabled?') }
    assert_equal(1, offenses.size)
    assert_equal(file, offenses.first[:location])
    assert_equal(2, offenses.first[:location_line])
    assert_includes(offenses.first[:message], '`::enabled?`')
  end

  it 'return tag inside overload does not report' do
    file = create_test_file('overload.rb', <<~RUBY)
      # Example class
      class Example
        # Checks readiness
        # @overload ready?(strict)
        #   @param strict [Boolean] strict mode
        #   @return [Boolean] true when ready
        def ready?(strict)
          strict
        end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: config)

    offenses = result.offenses.select { |o| o[:message].include?('ready?') }
    assert_empty(offenses, "Expected no offenses, got: #{offenses.inspect}")
  end

  it 'return tag without types does not report' do
    file = create_test_file('untyped.rb', <<~RUBY)
      # Example class
      class Example
        # Checks state
        # @return true when ok
        def ok?
          true
        end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: config)

    offenses = result.offenses.select { |o| o[:message].include?('ok?') }
    assert_empty(offenses, "Expected no offenses, got: #{offenses.inspect}")
  end

  it 'return tag from a macro does not report' do
    file = create_test_file('macro.rb', <<~RUBY)
      # Example class
      class Example
        # @!macro [new] predicate
        #   @return [Boolean] whether it is set
        # Checks if set
        def set?
          true
        end

        # Checks if other
        # @macro predicate
        def other?
          true
        end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: config)

    offenses = result.offenses.select do |o|
      o[:message].include?('set?') || o[:message].include?('other?')
    end
    assert_empty(offenses, "Expected no offenses, got: #{offenses.inspect}")
  end

  it 'macro generated boolean method does not report' do
    file = create_test_file('generated.rb', <<~RUBY)
      # Example class
      class Example
        # @!macro [attach] flag
        #   Checks the $1 flag
        # @param name [Symbol] flag name
        # @return [void]
        def self.flag(name); end

        flag :visible?
      end
    RUBY

    result = Yard::Lint.run(path: file, config: config)

    offenses = result.offenses.select { |o| o[:message].include?('visible?') }
    assert_empty(offenses, "Expected no offenses, got: #{offenses.inspect}")
  end

  it 'return tag line inside example reports' do
    file = create_test_file('example_return.rb', <<~RUBY)
      # Example class
      class Example
        # Tells if the flag is on
        # @example Check the flag
        #   flag.on? #=> true
        #   @return [Boolean] written inside an example
        def on?
          true
        end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: config)

    offenses = result.offenses.select do |o|
      o[:name] == 'UndocumentedObject' && o[:message].include?('on?')
    end
    assert_equal(1, offenses.size)
    assert_equal(7, offenses.first[:location_line])
  end

  it 'return assignment inside example reports' do
    file = create_test_file('example_assign.rb', <<~RUBY)
      # Example class
      class Example
        # Tells if the flag is set
        # @example
        #   @return = true
        def set?
          true
        end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: config)

    offenses = result.offenses.select { |o| o[:message].include?('set?') }
    assert_equal(1, offenses.size)
  end

  it 'macro line inside example reports' do
    file = create_test_file('example_macro.rb', <<~RUBY)
      # Example class
      class Example
        # Tells if the flag is off
        # @example
        #   @macro = value
        def off?
          false
        end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: config)

    offenses = result.offenses.select { |o| o[:message].include?('off?') }
    assert_equal(1, offenses.size)
  end

  it 'macro without return tag reports where it is defined and used' do
    file = create_test_file('macro_without_return.rb', <<~RUBY)
      # Example class
      class Gate
        # @!macro [new] gate_flag
        #   Says something about the gate
        def open?
          true
        end

        # @!macro gate_flag
        def shut?
          true
        end

        # @macro gate_flag
        def locked?
          true
        end

        # @!macro [new] gate_ret
        #   @return [Boolean] whether ajar
        def ajar?
          true
        end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: config)

    offenses = result.offenses.select { |o| o[:message].include?('Gate#') }
    reported = offenses.map { |o| o[:message][/Gate#\w+\?/] }.sort
    assert_equal(%w[Gate#locked? Gate#open? Gate#shut?], reported)
  end

  it 'macro defined in a file that is not linted does not report' do
    create_test_file('macro_def.rb', <<~RUBY)
      # Example class
      class Source
        # @!macro [new] xret
        #   @return [Boolean] whether it is so
        def defs?
          true
        end
      end
    RUBY
    file = create_test_file('macro_use.rb', <<~RUBY)
      # Example class
      class User
        # Tells if ready
        # @!macro xret
        def ready?
          true
        end

        # Tells if going
        # @macro xret
        def go?
          true
        end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: config)

    offenses = result.offenses.select { |o| o[:message].include?('User#') }
    assert_empty(offenses, "Expected no offenses, got: #{offenses.inspect}")
  end

  it 'return tag inside overload example reports' do
    file = create_test_file('overload_example.rb', <<~RUBY)
      # Example class
      class Example
        # Checks readiness
        # @overload ready?(strict)
        #   @param strict [Boolean] strict mode
        #   @example
        #     @return [Boolean] written inside an example
        def ready?(strict)
          strict
        end
      end
    RUBY

    result = Yard::Lint.run(path: file, config: config)

    offenses = result.offenses.select do |o|
      o[:name] == 'UndocumentedObject' && o[:message].include?('ready?')
    end
    assert_equal(1, offenses.size)
  end

  [[], ['--private']].each do |yard_options|
    describe "module_function methods with YardOptions #{yard_options.inspect}" do
      before do
        config.options = yard_options
      end

      it 'reports each form once on the module function at its line' do
        file = create_test_file('health.rb', <<~RUBY)
          # Module with module functions
          module Health
            # Tells if ready
            def ready?
              true
            end
            module_function :ready?

            # Tells if alive
            module_function def alive?
              true
            end

            module_function

            # Tells if healthy
            def healthy?
              true
            end
          end
        RUBY

        result = Yard::Lint.run(path: file, config: config)

        offenses = result.offenses
          .select { |o| o[:name].to_s == 'UndocumentedObject' }
          .map { |o| [o[:location_line], o[:message][/`([^`]+)`/, 1]] }
        assert_equal(
          [[4, 'Health.ready?'], [10, 'Health.alive?'], [17, 'Health.healthy?']],
          offenses.sort
        )
      end

      it 'does not report forms with a return tag' do
        file = create_test_file('health_documented.rb', <<~RUBY)
          # Module with module functions
          module Health
            # Tells if ready
            # @return [Boolean]
            def ready?
              true
            end
            module_function :ready?

            # Tells if alive
            # @return [Boolean]
            module_function def alive?
              true
            end

            module_function

            # Tells if healthy
            # @return [Boolean]
            def healthy?
              true
            end
          end
        RUBY

        result = Yard::Lint.run(path: file, config: config)

        assert_empty(result.offenses.select { |o| o[:name].to_s == 'UndocumentedObject' })
      end
    end
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


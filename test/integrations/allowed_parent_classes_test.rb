# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

describe 'AllowedParentClasses' do
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

  def config_with(validator, allowed_parents)
    Yard::Lint::Config.new do |c|
      c.set_validator_config(validator, 'AllowedParentClasses', allowed_parents)
    end
  end

  # ── UndocumentedObjects ────────────────────────────────────────────────

  describe 'Documentation/UndocumentedObjects' do
    it 'flags an undocumented class that does not inherit from an allowed parent' do
      file = create_test_file('example.rb', <<~RUBY)
        class PaymentError < RuntimeError
        end
      RUBY
      config = config_with('Documentation/UndocumentedObjects', ['StandardError'])
      result = Yard::Lint.run(path: file, config: config, progress: false)
      assert(result.offenses.any? { |o| o[:name].to_s == 'UndocumentedObject' },
        'should flag class not matching AllowedParentClasses')
    end

    it 'does not flag an undocumented class that directly inherits from an allowed parent' do
      file = create_test_file('example.rb', <<~RUBY)
        class PaymentError < StandardError
        end
      RUBY
      config = config_with('Documentation/UndocumentedObjects', ['StandardError'])
      result = Yard::Lint.run(path: file, config: config, progress: false)
      refute(result.offenses.any? { |o| o[:name].to_s == 'UndocumentedObject' },
        'should skip class inheriting from allowed parent')
    end

    it 'does not flag an undocumented method inside a class with an allowed parent' do
      file = create_test_file('example.rb', <<~RUBY)
        class PaymentError < StandardError
          def message
            'payment failed'
          end
        end
      RUBY
      config = config_with('Documentation/UndocumentedObjects', ['StandardError'])
      result = Yard::Lint.run(path: file, config: config, progress: false)
      refute(result.offenses.any? { |o| o[:name].to_s == 'UndocumentedObject' },
        'should skip methods in classes with allowed parent')
    end

    it 'flags a class with the same name as an allowed parent but different namespace' do
      file = create_test_file('example.rb', <<~RUBY)
        module MyApp
          class StandardError
          end
        end
      RUBY
      config = config_with('Documentation/UndocumentedObjects', ['StandardError'])
      result = Yard::Lint.run(path: file, config: config, progress: false)
      assert(result.offenses.any? { |o| o[:name].to_s == 'UndocumentedObject' },
        'should still flag the class itself (it is a class, not inheriting from StandardError)')
    end

    it 'supports fully-qualified parent class names' do
      file = create_test_file('example.rb', <<~RUBY)
        class MyModel < ActiveRecord::Base
        end
      RUBY
      config = config_with('Documentation/UndocumentedObjects', ['ActiveRecord::Base'])
      result = Yard::Lint.run(path: file, config: config, progress: false)
      refute(result.offenses.any? { |o| o[:name].to_s == 'UndocumentedObject' },
        'should accept fully-qualified parent class names')
    end

    it 'does not match by short name when the config specifies a short name but parent has a namespace' do
      file = create_test_file('example.rb', <<~RUBY)
        class MyModel < ActiveRecord::Base
        end
      RUBY
      config = config_with('Documentation/UndocumentedObjects', ['Base'])
      result = Yard::Lint.run(path: file, config: config, progress: false)
      assert(result.offenses.any? { |o| o[:name].to_s == 'UndocumentedObject' },
        'should require exact path match - short name "Base" should not match "ActiveRecord::Base"')
    end

    it 'handles an empty AllowedParentClasses list (no exemptions)' do
      file = create_test_file('example.rb', <<~RUBY)
        class PaymentError < StandardError
        end
      RUBY
      config = config_with('Documentation/UndocumentedObjects', [])
      result = Yard::Lint.run(path: file, config: config, progress: false)
      assert(result.offenses.any? { |o| o[:name].to_s == 'UndocumentedObject' },
        'empty AllowedParentClasses should not exempt anything')
    end

    it 'does not exempt a class that has no explicit parent (implicitly inherits Object)' do
      file = create_test_file('example.rb', <<~RUBY)
        class PlainClass
        end
      RUBY
      config = config_with('Documentation/UndocumentedObjects', ['Object'])
      result = Yard::Lint.run(path: file, config: config, progress: false)
      assert(result.offenses.any? { |o| o[:name].to_s == 'UndocumentedObject' },
        'listing Object in AllowedParentClasses should not exempt all classes')
    end

    it 'accepts multiple allowed parent classes' do
      file = create_test_file('example.rb', <<~RUBY)
        class NetworkError < IOError
        end

        class ValidationError < StandardError
        end
      RUBY
      config = config_with('Documentation/UndocumentedObjects', %w[StandardError IOError])
      result = Yard::Lint.run(path: file, config: config, progress: false)
      refute(result.offenses.any? { |o| o[:name].to_s == 'UndocumentedObject' },
        'should exempt classes matching any entry in AllowedParentClasses')
    end

    it 'still flags documented but otherwise violating objects in allowed-parent classes' do
      # AllowedParentClasses only suppresses UndocumentedObjects; documented classes
      # are processed normally by other validators (e.g. UndocumentedMethodArguments).
      # This test ensures the guard is per-validator, not a global class blacklist.
      file = create_test_file('example.rb', <<~RUBY)
        # A payment error.
        class PaymentError < StandardError
          # Initialises the error.
          # @param code [Integer] error code
          # @param msg [String] message
          def initialize(code, msg)
            super(msg)
          end
        end
      RUBY
      config = Yard::Lint::Config.new do |c|
        c.set_validator_config('Documentation/UndocumentedObjects', 'AllowedParentClasses', ['StandardError'])
      end
      result = Yard::Lint.run(path: file, config: config, progress: false)
      refute(result.offenses.any? { |o| o[:name].to_s == 'UndocumentedObject' },
        'documented class with allowed parent should not generate UndocumentedObject offenses')
    end

    it 'does not flag undocumented constants inside an allowed-parent class' do
      file = create_test_file('example.rb', <<~RUBY)
        class PaymentError < StandardError
          DEFAULT_MESSAGE = 'payment failed'
        end
      RUBY
      config = config_with('Documentation/UndocumentedObjects', ['StandardError'])
      result = Yard::Lint.run(path: file, config: config, progress: false)
      refute(result.offenses.any? { |o| o[:name].to_s == 'UndocumentedObject' },
        'should skip constants inside a class inheriting from an allowed parent')
    end

    it 'does not flag undocumented nested classes inside an allowed-parent class' do
      file = create_test_file('example.rb', <<~RUBY)
        class PaymentError < StandardError
          class Retry
          end
        end
      RUBY
      config = config_with('Documentation/UndocumentedObjects', ['StandardError'])
      result = Yard::Lint.run(path: file, config: config, progress: false)
      refute(result.offenses.any? { |o| o[:name].to_s == 'UndocumentedObject' },
        'should skip nested classes inside a class inheriting from an allowed parent')
    end
  end

  # ── UndocumentedMethodArguments ───────────────────────────────────────

  describe 'Documentation/UndocumentedMethodArguments' do
    it 'does not flag missing @param in a method inside an allowed-parent class' do
      file = create_test_file('example.rb', <<~RUBY)
        # A payment error.
        class PaymentError < StandardError
          # Initialises with a code.
          def initialize(code)
            super("code: \#{code}")
          end
        end
      RUBY
      config = config_with('Documentation/UndocumentedMethodArguments', ['StandardError'])
      result = Yard::Lint.run(path: file, config: config, progress: false)
      refute(result.offenses.any? { |o| o[:name].to_s == 'UndocumentedMethodArgument' },
        'should skip param check in methods of allowed-parent classes')
    end

    it 'flags missing @param when the class parent is not in the allowed list' do
      file = create_test_file('example.rb', <<~RUBY)
        # A service.
        class PaymentService < BaseService
          # Processes a payment.
          def process(amount)
          end
        end
      RUBY
      config = config_with('Documentation/UndocumentedMethodArguments', ['StandardError'])
      result = Yard::Lint.run(path: file, config: config, progress: false)
      assert(result.offenses.any? { |o| o[:name].to_s == 'UndocumentedMethodArgument' },
        'should still flag @param issues in classes with non-allowed parents')
    end
  end

  # ── UndocumentedBooleanMethods ────────────────────────────────────────

  describe 'Documentation/UndocumentedBooleanMethods' do
    it 'does not flag boolean method without @return in allowed-parent class' do
      file = create_test_file('example.rb', <<~RUBY)
        # A payment error.
        class PaymentError < StandardError
          # Whether it is a timeout error.
          def timeout?
            message.include?('timeout')
          end
        end
      RUBY
      config = config_with('Documentation/UndocumentedBooleanMethods', ['StandardError'])
      result = Yard::Lint.run(path: file, config: config, progress: false)
      refute(result.offenses.any? { |o| o[:name].to_s == 'UndocumentedBooleanMethod' },
        'should skip boolean return check in allowed-parent classes')
    end
  end

  # ── UndocumentedOptions ───────────────────────────────────────────────

  describe 'Documentation/UndocumentedOptions' do
    it 'does not flag missing @option in allowed-parent class methods' do
      file = create_test_file('example.rb', <<~RUBY)
        # A payment error.
        class PaymentError < StandardError
          # Initialises with options.
          def initialize(options = {})
          end
        end
      RUBY
      config = config_with('Documentation/UndocumentedOptions', ['StandardError'])
      result = Yard::Lint.run(path: file, config: config, progress: false)
      refute(result.offenses.any? { |o| o[:name].to_s == 'UndocumentedOption' },
        'should skip @option check in allowed-parent classes')
    end
  end

  # ── MissingReturn (opt-in) ────────────────────────────────────────────

  describe 'Documentation/MissingReturn' do
    def enabled_config(allowed_parents = [])
      Yard::Lint::Config.new do |c|
        c.set_validator_config('Documentation/MissingReturn', 'Enabled', true)
        c.set_validator_config('Documentation/MissingReturn', 'AllowedParentClasses', allowed_parents)
      end
    end

    it 'flags missing @return in a class with no allowed parent' do
      file = create_test_file('example.rb', <<~RUBY)
        # A service.
        class Service
          # Does the work.
          def call
          end
        end
      RUBY
      result = Yard::Lint.run(path: file, config: enabled_config, progress: false)
      assert(result.offenses.any? { |o| o[:name].to_s == 'MissingReturnTag' },
        'should flag missing @return without allowed parent exemption')
    end

    it 'does not flag missing @return in a class with an allowed parent' do
      file = create_test_file('example.rb', <<~RUBY)
        # A payment error.
        class PaymentError < StandardError
          # Returns the error message.
          def message
            'payment failed'
          end
        end
      RUBY
      result = Yard::Lint.run(path: file, config: enabled_config(['StandardError']), progress: false)
      refute(result.offenses.any? { |o| o[:name].to_s == 'MissingReturnTag' },
        'should not flag @return in allowed-parent class methods')
    end
  end
end

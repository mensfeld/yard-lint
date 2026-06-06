# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

describe 'AllowedMethods (Documentation/UndocumentedMethodArguments)' do
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

  def config_with_allowed(allowed_methods)
    Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedMethodArguments', 'AllowedMethods', allowed_methods)
    end
  end

  def offense?(result)
    result.offenses.any? { |o| o[:name].to_s == 'UndocumentedMethodArgument' }
  end

  def lint(file, config)
    Yard::Lint.run(path: file, config: config, progress: false)
  end

  # ── Baseline: the feature is off by default ────────────────────────────

  it 'flags undocumented params when AllowedMethods is empty (default)' do
    file = create_test_file('example.rb', <<~RUBY)
      # A service.
      class MyService
        # Does the work.
        def call(input)
        end
      end
    RUBY
    result = lint(file, config_with_allowed([]))
    assert(offense?(result), 'should flag missing @param with empty AllowedMethods')
  end

  # ── Exact name matching ────────────────────────────────────────────────

  it 'skips @param check for a method matched by exact name' do
    file = create_test_file('example.rb', <<~RUBY)
      # A service.
      class MyService
        # Does the work.
        def call(input)
        end
      end
    RUBY
    result = lint(file, config_with_allowed(['call']))
    refute(offense?(result), 'should skip @param check for "call" when it is in AllowedMethods')
  end

  it 'exact name match is case-sensitive' do
    file = create_test_file('example.rb', <<~RUBY)
      # A service.
      class MyService
        # Does the work.
        def Call(input)
        end
      end
    RUBY
    result = lint(file, config_with_allowed(['call']))
    assert(offense?(result), '"Call" (capital C) should not match allowed "call"')
  end

  it 'exact name match skips method regardless of arity' do
    file = create_test_file('example.rb', <<~RUBY)
      # A service.
      class MyService
        # Processes one arg.
        def perform(job)
        end

        # Processes two args.
        def perform(job, context)
        end
      end
    RUBY
    result = lint(file, config_with_allowed(['perform']))
    refute(offense?(result), 'exact name match should skip the method at any arity')
  end

  it 'only skips the specified method, not others in the same class' do
    file = create_test_file('example.rb', <<~RUBY)
      # A service.
      class MyService
        # Does the work.
        def call(input)
        end

        # Processes a record.
        def process(record)
        end
      end
    RUBY
    result = lint(file, config_with_allowed(['call']))
    offending = result.offenses.select { |o| o[:name].to_s == 'UndocumentedMethodArgument' }
    assert(offending.none? { |o| o[:message].to_s.include?('call') },
      'should skip "call"')
    assert(offending.any? { |o| o[:message].to_s.include?('process') },
      'should still flag "process"')
  end

  it 'supports multiple allowed method names' do
    file = create_test_file('example.rb', <<~RUBY)
      # A service.
      class MyService
        # Executes the job.
        def call(job)
        end

        # Runs the task.
        def perform(task)
        end
      end
    RUBY
    result = lint(file, config_with_allowed(%w[call perform]))
    refute(offense?(result), 'should skip both "call" and "perform"')
  end

  # ── Arity notation ─────────────────────────────────────────────────────

  it 'skips @param check when method name and arity both match' do
    file = create_test_file('example.rb', <<~RUBY)
      # A service.
      class MyService
        # Initialises with one required param.
        def initialize(config)
          @config = config
        end
      end
    RUBY
    result = lint(file, config_with_allowed(['initialize/1']))
    refute(offense?(result), 'initialize/1 should match initialize with 1 required param')
  end

  it 'does not skip when arity does not match' do
    file = create_test_file('example.rb', <<~RUBY)
      # A service.
      class MyService
        # Initialises with two params.
        def initialize(config, logger)
          @config = config
          @logger = logger
        end
      end
    RUBY
    result = lint(file, config_with_allowed(['initialize/1']))
    assert(offense?(result), 'initialize/1 should not match initialize with 2 params')
  end

  it 'arity excludes splat parameters from count' do
    file = create_test_file('example.rb', <<~RUBY)
      # A service.
      class MyService
        # Broadcasts an event.
        def broadcast(event, *listeners)
        end
      end
    RUBY
    # arity = 1 (only `event`; `*listeners` is excluded)
    result = lint(file, config_with_allowed(['broadcast/1']))
    refute(offense?(result), 'splat params should not count toward arity')
  end

  it 'arity excludes block parameters from count' do
    file = create_test_file('example.rb', <<~RUBY)
      # A service.
      class MyService
        # Runs with a block.
        def run(name, &block)
        end
      end
    RUBY
    # arity = 1 (only `name`; `&block` is excluded)
    result = lint(file, config_with_allowed(['run/1']))
    refute(offense?(result), 'block params should not count toward arity')
  end

  it 'arity counts optional parameters' do
    file = create_test_file('example.rb', <<~RUBY)
      # A service.
      class MyService
        # Connects with optional port.
        def connect(host, port = 80)
        end
      end
    RUBY
    # arity = 2 (required + optional, excluding * and &)
    result = lint(file, config_with_allowed(['connect/2']))
    refute(offense?(result), 'optional params should count toward arity')
  end

  it 'arity notation with zero matches a no-param method' do
    file = create_test_file('example.rb', <<~RUBY)
      # A service.
      class MyService
        # No-arg initialize.
        def initialize
        end
      end
    RUBY
    # no parameters → arity 0; but also no params means no @param needed
    result = lint(file, config_with_allowed(['initialize/0']))
    refute(offense?(result), 'initialize/0 should match no-param initialize')
  end

  # ── Regex matching ─────────────────────────────────────────────────────

  it 'skips @param check when method name matches a regex pattern' do
    file = create_test_file('example.rb', <<~RUBY)
      # A service.
      class MyService
        # Performs the main job.
        def perform_job(job)
        end
      end
    RUBY
    result = lint(file, config_with_allowed(['/^perform/']))
    refute(offense?(result), 'regex /^perform/ should match perform_job')
  end

  it 'regex does not match methods that do not fit the pattern' do
    file = create_test_file('example.rb', <<~RUBY)
      # A service.
      class MyService
        # Handles an event.
        def handle(event)
        end
      end
    RUBY
    result = lint(file, config_with_allowed(['/^perform/']))
    assert(offense?(result), 'regex /^perform/ should not match "handle"')
  end

  it 'regex supports anchors and complex patterns' do
    file = create_test_file('example.rb', <<~RUBY)
      # A repo.
      class MyRepo
        # Finds by primary key.
        def find_by_id(id)
        end

        # Finds by email.
        def find_by_email(email)
        end

        # Saves the record.
        def save(record)
        end
      end
    RUBY
    result = lint(file, config_with_allowed(['/^find_by_/']))
    offending = result.offenses.select { |o| o[:name].to_s == 'UndocumentedMethodArgument' }
    refute(offending.any? { |o| o[:message].to_s.include?('find_by') },
      'should skip all find_by_* methods')
    assert(offending.any? { |o| o[:message].to_s.include?('save') },
      'should still flag "save"')
  end

  it 'invalid regex pattern is silently ignored (does not crash)' do
    file = create_test_file('example.rb', <<~RUBY)
      # A service.
      class MyService
        # Does the work.
        def call(input)
        end
      end
    RUBY
    result = lint(file, config_with_allowed(['/[invalid regex/']))
    assert(offense?(result), 'invalid regex should be ignored, method should still be flagged')
  end

  it 'empty regex // is rejected and does not match everything' do
    file = create_test_file('example.rb', <<~RUBY)
      # A service.
      class MyService
        # Does the work.
        def call(input)
        end
      end
    RUBY
    result = lint(file, config_with_allowed(['//']))
    assert(offense?(result), 'empty regex // should be rejected and not exempt all methods')
  end

  # ── Mixed patterns ─────────────────────────────────────────────────────

  it 'supports a mix of exact, arity, and regex patterns' do
    file = create_test_file('example.rb', <<~RUBY)
      # A handler.
      class Handler
        # Calls with one arg.
        def call(input)
        end

        # Initialises with two args.
        def initialize(config, logger)
        end

        # Performs async.
        def perform_async(job)
        end

        # Other method.
        def process(record)
        end
      end
    RUBY
    result = lint(file, config_with_allowed(['call', 'initialize/2', '/^perform/']))
    offending = result.offenses.select { |o| o[:name].to_s == 'UndocumentedMethodArgument' }
    refute(offending.any? { |o| o[:message].to_s.include?('call') }, 'call should be skipped')
    refute(offending.any? { |o| o[:message].to_s.include?('initialize') }, 'initialize/2 should be skipped')
    refute(offending.any? { |o| o[:message].to_s.include?('perform_async') }, 'perform_async should be skipped')
    assert(offending.any? { |o| o[:message].to_s.include?('process') }, 'process should still be flagged')
  end

  # ── Interaction with existing guards ───────────────────────────────────

  it 'is independent of AllowedParentClasses (both can be active)' do
    file = create_test_file('example.rb', <<~RUBY)
      class AppError < StandardError
        # Initialises the error.
        def initialize(msg, context)
        end
      end

      # A service.
      class MyService
        # Does the work.
        def call(input)
        end

        # Processes a record.
        def process(record)
        end
      end
    RUBY
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedMethodArguments', 'AllowedParentClasses', ['StandardError'])
      c.set_validator_config('Documentation/UndocumentedMethodArguments', 'AllowedMethods', ['call'])
    end
    result = Yard::Lint.run(path: file, config: config, progress: false)
    offending = result.offenses.select { |o| o[:name].to_s == 'UndocumentedMethodArgument' }
    refute(offending.any? { |o| o[:message].to_s.include?('initialize') },
      'initialize inside StandardError subclass should be exempt via AllowedParentClasses')
    refute(offending.any? { |o| o[:message].to_s.include?('call') },
      '"call" should be exempt via AllowedMethods')
    assert(offending.any? { |o| o[:message].to_s.include?('process') },
      '"process" is not in AllowedMethods and not in an allowed parent class — should be flagged')
  end

  it 'does not affect UndocumentedObjects — only @param checking is skipped' do
    file = create_test_file('example.rb', <<~RUBY)
      class MyService
        def call(input)
        end
      end
    RUBY
    result = lint(file, config_with_allowed(['call']))
    undoc = result.offenses.select { |o| o[:name].to_s == 'UndocumentedObject' }
    assert(undoc.any?, 'UndocumentedObjects should still flag the undocumented class/method')
  end

  it 'does not skip methods that are already fully documented' do
    file = create_test_file('example.rb', <<~RUBY)
      # A service.
      class MyService
        # Processes input.
        # @param input [String] the input string
        # @return [void]
        def call(input)
        end
      end
    RUBY
    result = lint(file, config_with_allowed([]))
    refute(offense?(result), 'fully documented method should never be flagged regardless of AllowedMethods')
  end

  it 'alias methods are not flagged regardless of AllowedMethods' do
    file = create_test_file('example.rb', <<~RUBY)
      # A service.
      class MyService
        # Does the work.
        # @param input [String] the input
        def call(input)
        end

        alias execute call
      end
    RUBY
    result = lint(file, config_with_allowed([]))
    refute(offense?(result), 'aliases should never be flagged (existing behavior unchanged)')
  end

  # ── Pattern edge cases ─────────────────────────────────────────────────

  it 'nil and blank entries in AllowedMethods are silently ignored' do
    file = create_test_file('example.rb', <<~RUBY)
      # A service.
      class MyService
        # Does the work.
        def call(input)
        end
      end
    RUBY
    result = lint(file, config_with_allowed([nil, '', '  ', 'call']))
    refute(offense?(result), 'nil/blank entries should be stripped; "call" should still match')
  end

  it 'arity pattern with non-numeric arity is silently ignored' do
    file = create_test_file('example.rb', <<~RUBY)
      # A service.
      class MyService
        # Does the work.
        def call(input)
        end
      end
    RUBY
    result = lint(file, config_with_allowed(['call/abc']))
    # 'call/abc' looks like an arity pattern but 'abc' is not numeric → treated as exact name
    # 'call/abc' as exact name won't match 'call', so the method is flagged
    assert(offense?(result), 'malformed arity pattern should not accidentally exempt the method')
  end

  it 'multi-slash pattern like call/1/2 does not accidentally match call with arity 1' do
    file = create_test_file('example.rb', <<~RUBY)
      # A service.
      class MyService
        # Does the work.
        def call(input)
        end
      end
    RUBY
    result = lint(file, config_with_allowed(['call/1/2']))
    assert(offense?(result), 'call/1/2 is not a valid arity pattern and should not exempt the method')
  end

  it 'whitespace around pattern entries is stripped' do
    file = create_test_file('example.rb', <<~RUBY)
      # A service.
      class MyService
        # Does the work.
        def call(input)
        end
      end
    RUBY
    result = lint(file, config_with_allowed(['  call  ']))
    refute(offense?(result), 'leading/trailing whitespace in pattern should be stripped')
  end
end

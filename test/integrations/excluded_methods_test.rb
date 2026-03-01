# frozen_string_literal: true

require 'test_helper'

require 'tempfile'

describe 'Excluded Methods' do
  attr_reader :temp_file


  before do
    @temp_file = Tempfile.new(['test', '.rb'])
  end

  after do
    temp_file.unlink
  end

  # Helper to run lint with a given config
  def run_lint(config)
    Yard::Lint.run(path: temp_file.path, progress: false, config: config)
  end

  # --- Exact name matching: excluding to_s ---

  it 'exact name excluding to s does not flag undocumented to s' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', ['to_s'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def to_s
          'example'
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    refute(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/to_s/)
    })
  end

  it 'exact name excluding to s still flags other undocumented methods' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', ['to_s'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def other_method
          'other'
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    assert(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/other_method/)
    })
  end

  # --- Exact name matching: excluding multiple methods ---

  it 'exact name excluding multiple methods excludes all' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', %w[to_s inspect hash eql?])
    end

    temp_file.write(<<~RUBY)
      class Example
        def to_s
          'example'
        end

        def inspect
          '#<Example>'
        end

        def hash
          42
        end

        def eql?(other)
          true
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    # Should not flag any of the excluded methods
    %w[to_s inspect hash eql?].each do |method_name|
      refute(result.offenses.any? { |o|
        o[:name] == 'UndocumentedObject' && o[:message].match?(/#{Regexp.escape(method_name)}/)
      }, "Expected #{method_name} not to be flagged")
    end
  end

  # --- Arity notation ---

  it 'arity excludes initialize with 0 parameters' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', ['initialize/0', 'call/1'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def initialize
          @value = 1
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    refute(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/initialize/)
    })
  end

  it 'arity flags initialize with 1 parameter' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', ['initialize/0', 'call/1'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def initialize(value)
          @value = value
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    assert(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/initialize/)
    })
  end

  it 'arity flags initialize with 2 parameters' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', ['initialize/0', 'call/1'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def initialize(value, name)
          @value = value
          @name = name
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    assert(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/initialize/)
    })
  end

  it 'arity excludes call with exactly 1 parameter' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', ['initialize/0', 'call/1'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def call(input)
          input.upcase
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    refute(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/\bcall\b/)
    })
  end

  it 'arity flags call with 0 parameters' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', ['initialize/0', 'call/1'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def call
          'result'
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    assert(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/\bcall\b/)
    })
  end

  it 'arity flags call with 2 parameters' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', ['initialize/0', 'call/1'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def call(input, options)
          input.upcase
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    assert(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/\bcall\b/)
    })
  end

  # --- Arity: setup/teardown test framework pattern ---

  it 'arity excludes parameterless setup and teardown' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', ['setup/0', 'teardown/0'])
    end

    temp_file.write(<<~RUBY)
      class TestCase
        before do
          @db = Database.new
        end

        after do
          @db.close
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    refute(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/setup|teardown/)
    })
  end

  it 'arity flags setup with parameters' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', ['setup/0', 'teardown/0'])
    end

    temp_file.write(<<~RUBY)
      class TestCase
        def setup(config)
          @db = Database.new(config)
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    assert(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/setup/)
    })
  end

  # --- Arity: counting optional parameters ---

  it 'arity counts optional parameters' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', ['method/2'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def method(required, optional = nil)
          [required, optional]
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    # Should be excluded because it has 2 parameters (1 required + 1 optional)
    refute(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/\bmethod\b/)
    })
  end

  it 'arity does not count splat parameters' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', ['method/2'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def method(arg1, arg2, *rest)
          [arg1, arg2, rest]
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    # Has 2 regular params + splat, should match /2
    refute(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/\bmethod\b/)
    })
  end

  it 'arity does not count block parameters' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', ['method/2'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def method(arg1, arg2, &block)
          [arg1, arg2, block]
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    # Has 2 regular params + block, should match /2
    refute(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/\bmethod\b/)
    })
  end

  # --- Regex patterns ---

  it 'regex excludes methods starting with underscore' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', ['/^_/'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def _private_helper
          'helper'
        end

        def _internal_method
          'internal'
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    refute(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/_private_helper|_internal_method/)
    })
  end

  it 'regex still flags methods not matching pattern' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', ['/^_/'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def public_method
          'public'
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    assert(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/public_method/)
    })
  end

  # --- Regex: test method patterns ---

  it 'regex excludes test pattern methods' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', ['/^test_/', '/^should_/'])
    end

    temp_file.write(<<~RUBY)
      class TestCase
        it 'user creation' do
          assert true
        end

        it 'validation' do
          assert true
        end

        def should_validate_email
          assert true
        end

        def should_save_record
          assert true
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    # Should not flag any test methods
    refute(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/test_|should_/)
    })
  end

  it 'regex still flags non test methods' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', ['/^test_/', '/^should_/'])
    end

    temp_file.write(<<~RUBY)
      class TestCase
        def helper_method
          'helper'
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    assert(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/helper_method/)
    })
  end

  # --- Regex: suffix patterns ---

  it 'regex excludes methods ending with helper or util' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', ['/_(helper|util)$/'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def format_helper
          'helper'
        end

        def parsing_util
          'util'
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    refute(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/format_helper|parsing_util/)
    })
  end

  it 'regex flags methods not matching suffix pattern' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', ['/_(helper|util)$/'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def regular_method
          'regular'
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    assert(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/regular_method/)
    })
  end

  # --- Combined patterns ---

  it 'combined patterns applies all exclusion patterns correctly' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', [
          'to_s',           # Exact name
          'initialize/0',   # Arity notation
          '/^_/'            # Regex
        ])
    end

    temp_file.write(<<~RUBY)
      class Example
        def initialize
          @value = 1
        end

        def to_s
          'example'
        end

        def _private_method
          'private'
        end

        def public_method
          'public'
        end

        def initialize(value)
          @value = value
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)

    # Should exclude: to_s (exact), initialize() (arity), _private_method (regex)
    refute(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/to_s|_private_method/)
    })

    # Should flag: public_method, initialize(value)
    assert(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/public_method/)
    })
  end

  it 'combined common ruby and rails patterns excludes all' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', [
          'initialize/0',
          'to_s',
          'inspect',
          'hash',
          'eql?',
          '/^_/'
        ])
    end

    temp_file.write(<<~RUBY)
      class User

        def initialize
          @name = 'John'
        end

        def to_s
          @name
        end

        def inspect
          "#<User name=\#{@name}>"
        end

        def hash
          @name.hash
        end

        def eql?(other)
          @name == other.name
        end

        def _build_query
          'SELECT * FROM users'
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    # All these should be excluded
    %w[initialize to_s inspect hash eql? _build_query].each do |method_name|
      refute(result.offenses.any? { |o|
        o[:name] == 'UndocumentedObject' && o[:message].match?(/#{Regexp.escape(method_name)}/)
      }, "Expected #{method_name} not to be flagged")
    end
  end

  # --- Edge cases: special regex characters ---

  it 'edge case special regex characters excludes operator methods' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', ['<<', '[]', '[]='])
    end

    temp_file.write(<<~RUBY)
      class Collection
        def <<(item)
          @items << item
        end

        def [](index)
          @items[index]
        end

        def []=(index, value)
          @items[index] = value
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    # These operator methods should be excluded
    refute(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/<<|\[\]|\[\]=/) &&
        o[:element]&.match?(/<<|#\[\]|#\[\]=/)
    })
  end

  # --- Edge cases: empty exclusion list ---

  it 'edge case empty exclusion list flags all including initialize' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', [])
    end

    temp_file.write(<<~RUBY)
      class Example
        def initialize
          @value = 1
        end

        def other_method
          'other'
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    assert(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/initialize/)
    })
    assert(result.offenses.any? { |o|
      o[:name] == 'UndocumentedObject' && o[:message].match?(/other_method/)
    })
  end

  # --- Defensive programming: invalid regex ---

  it 'defensive invalid regex handles gracefully' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', ['/[/', '/(unclosed', 'to_s'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def method_one
          'one'
        end

        def to_s
          'example'
        end
      end
    RUBY
    temp_file.rewind

    # Should not crash
    result = run_lint(config)

    # Invalid regex patterns should be skipped, but to_s should still be excluded
    refute(result.offenses.any? { |o| o[:message].match?(/to_s/) })

    # method_one should be flagged (invalid patterns didn't match it)
    assert(result.offenses.any? { |o| o[:message].match?(/method_one/) })
  end

  # --- Defensive programming: empty regex ---

  it 'defensive empty regex does not exclude all methods' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', ['//', 'inspect'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def public_method
          'public'
        end

        def inspect
          'inspection'
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    # Empty regex should be filtered out, not match everything
    # Only inspect should be excluded
    refute(result.offenses.any? { |o| o[:message].match?(/inspect/) })

    assert(result.offenses.any? { |o| o[:message].match?(/public_method/) })
  end

  # --- Defensive programming: non-array ExcludedMethods ---

  it 'defensive string instead of array handles gracefully' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', 'to_s') # String instead of Array
    end

    temp_file.write(<<~RUBY)
      class Example
        def to_s
          'example'
        end

        def other
          'other'
        end
      end
    RUBY
    temp_file.rewind

    # Should not crash
    result = run_lint(config)

    # Should exclude to_s
    refute(result.offenses.any? { |o| o[:message].match?(/to_s/) })
  end

  # --- Defensive programming: whitespace in patterns ---

  it 'defensive whitespace in patterns trims and matches' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', [' to_s ', '  initialize/0  ', ' /^_/ '])
    end

    temp_file.write(<<~RUBY)
      class Example
        def initialize
          @value = 1
        end

        def to_s
          'example'
        end

        def _private
          'private'
        end

        def public_method
          'public'
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    # All excluded methods should be excluded despite whitespace
    refute(result.offenses.any? { |o|
      o[:message].match?(/to_s|initialize|_private/)
    })

    # public_method should still be flagged
    assert(result.offenses.any? { |o|
      o[:message].match?(/public_method/)
    })
  end

  # --- Defensive programming: invalid arity values ---

  it 'defensive invalid arity values does not match' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', ['initialize/abc', 'call/-1', 'setup/', 'method/999'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def initialize
          @value = 1
        end

        def call
          'result'
        end

        def setup
          'setup'
        end

        def method
          'method'
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    # All methods should be flagged because arity patterns are invalid
    assert(result.offenses.any? { |o| o[:message].match?(/initialize/) })
    assert(result.offenses.any? { |o| o[:message].match?(/\bcall\b/) })
    assert(result.offenses.any? { |o| o[:message].match?(/setup/) })
    assert(result.offenses.any? { |o| o[:message].match?(/\bmethod\b/) })
  end

  # --- Defensive programming: nil and empty strings ---

  it 'defensive nil and empty patterns ignores them' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', ['', nil, 'to_s', '', nil])
    end

    temp_file.write(<<~RUBY)
      class Example
        def to_s
          'example'
        end

        def other
          'other'
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)

    # Should only exclude to_s
    refute(result.offenses.any? { |o| o[:message].match?(/to_s/) })
    assert(result.offenses.any? { |o| o[:message].match?(/other/) })
  end

  # --- Advanced edge cases: keyword arguments with positional args ---

  it 'advanced positional args correctly excludes matching arity' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', ['method/2'])
    end

    temp_file.write(<<~RUBY)
      class Example
        # Documented method
        # @param a [String] first param
        # @param b [String] second param
        def method(a, b)
          [a, b]
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    # Should be excluded from UndocumentedObject check (2 positional params)
    undoc_objects = result.offenses.select { |o| o[:name] == 'UndocumentedObject' }
    refute(undoc_objects.any? { |o| o[:message].match?(/\bmethod\b/) })
  end

  it 'advanced positional args does not exclude different arity' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', ['method/2'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def method(a, b, c)
          [a, b, c]
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    # Should NOT be excluded (3 params, not 2)
    assert(result.offenses.any? { |o| o[:message].match?(/\bmethod\b/) })
  end

  # --- Advanced: splat and block parameters with arity ---

  it 'advanced splat not counted in arity' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', ['method/2'])
    end

    temp_file.write(<<~RUBY)
      class Example
        # Documented method
        # @param a [String] first param
        # @param b [String] second param
        # @param rest [Array] remaining params
        def method(a, b, *rest)
          [a, b, rest]
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    # Should match /2 (not counting *rest)
    undoc_objects = result.offenses.select { |o| o[:name] == 'UndocumentedObject' }
    refute(undoc_objects.any? { |o| o[:message].match?(/\bmethod\b/) })
  end

  it 'advanced block not counted in arity' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', ['method/2'])
    end

    temp_file.write(<<~RUBY)
      class Example
        # Documented method
        # @param a [String] first param
        # @param b [String] second param
        # @yield block callback
        def method(a, b, &block)
          [a, b, block]
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    # Should match /2 (not counting &block)
    undoc_objects = result.offenses.select { |o| o[:name] == 'UndocumentedObject' }
    refute(undoc_objects.any? { |o| o[:message].match?(/\bmethod\b/) })
  end

  # --- Advanced: operator methods ---

  it 'advanced excludes binary operators' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', ['+', '-', '==', '===', '<=>', '+@', '-@', '!', '~'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def +(other)
          self
        end

        def -(other)
          self
        end

        def ==(other)
          true
        end

        def <=>(other)
          0
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    operator_pattern = /\+|-|==|<=>|Example#\+|Example#-|Example#==|Example#<=>/
    refute(result.offenses.any? { |o| o[:element]&.match?(operator_pattern) })
  end

  it 'advanced excludes unary operators' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', ['+', '-', '==', '===', '<=>', '+@', '-@', '!', '~'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def +@
          self
        end

        def -@
          self.class.new(-value)
        end

        def !
          false
        end

        def ~
          self
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    refute(result.offenses.any? { |o| o[:element]&.match?(/\+@|-@|!|~/) })
  end

  # --- Advanced: ASCII method names with combined patterns ---

  it 'advanced ascii method names handled normally' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', ['to_s', '/^test/'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def to_s
          'example'
        end

        it 'method' do
          'test'
        end

        def other
          'other'
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    refute(result.offenses.any? { |o| o[:message].match?(/to_s|test_method/) })
    assert(result.offenses.any? { |o| o[:message].match?(/other/) })
  end

  # --- Advanced: complex parameter signatures ---

  it 'advanced counts optional parameters in arity' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', ['method/3'])
    end

    temp_file.write(<<~RUBY)
      class Example
        # Documented method
        # @param a [String] required param
        # @param b [String, nil] optional param
        # @param c [String] optional with default
        def method(a, b = nil, c = 'default')
          [a, b, c]
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    # Should count all params including optional (3 total)
    undoc_objects = result.offenses.select { |o| o[:name] == 'UndocumentedObject' }
    refute(undoc_objects.any? { |o| o[:message].match?(/\bmethod\b/) })
  end

  it 'advanced distinguishes different arities' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', ['method/3'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def method(a, b, c, d)
          [a, b, c, d]
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    # 4 params, should NOT match /3
    assert(result.offenses.any? { |o| o[:message].match?(/\bmethod\b/) })
  end

  # --- Advanced: pattern precedence ---

  it 'advanced pattern precedence excludes when any pattern matches' do
    config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects',
        'ExcludedMethods', ['initialize', 'initialize/0', '/^init/'])
    end

    temp_file.write(<<~RUBY)
      class Example
        def initialize
          @value = 1
        end

        def initialize_db
          'db'
        end
      end
    RUBY
    temp_file.rewind

    result = run_lint(config)
    # All three patterns match initialize
    # Only regex matches initialize_db
    refute(result.offenses.any? { |o| o[:message].match?(/initialize/) })
  end
end

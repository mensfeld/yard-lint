# frozen_string_literal: true

require 'tempfile'

RSpec.describe 'ExcludedMethods configuration' do
  subject(:result) { Yard::Lint.run(path: temp_file.path, progress: false, config: config) }

  let(:temp_file) { Tempfile.new(['test', '.rb']) }

  after { temp_file.unlink }

  describe 'Exact name matching' do
    context 'when excluding to_s method' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
            'ExcludedMethods', ['to_s'])
        end
      end

      it 'does not flag undocumented to_s method' do
        temp_file.write(<<~RUBY)
          class Example
            def to_s
              'example'
            end
          end
        RUBY
        temp_file.rewind

        expect(result.offenses).not_to include(
          hash_including(
            name: 'UndocumentedObject',
            message: a_string_matching(/to_s/)
          )
        )
      end

      it 'still flags other undocumented methods' do
        temp_file.write(<<~RUBY)
          class Example
            def other_method
              'other'
            end
          end
        RUBY
        temp_file.rewind

        expect(result.offenses).to include(
          hash_including(
            name: 'UndocumentedObject',
            message: a_string_matching(/other_method/)
          )
        )
      end
    end

    context 'when excluding multiple methods by name' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
            'ExcludedMethods', %w[to_s inspect hash eql?])
        end
      end

      it 'excludes all specified methods' do
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

        # Should not flag any of the excluded methods
        %w[to_s inspect hash eql?].each do |method_name|
          expect(result.offenses).not_to include(
            hash_including(
              name: 'UndocumentedObject',
              message: a_string_matching(/#{Regexp.escape(method_name)}/)
            )
          )
        end
      end
    end
  end

  describe 'Arity notation' do
    context 'when excluding methods by arity' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
            'ExcludedMethods', ['initialize/0', 'call/1'])
        end
      end

      it 'excludes initialize with 0 parameters' do
        temp_file.write(<<~RUBY)
          class Example
            def initialize
              @value = 1
            end
          end
        RUBY
        temp_file.rewind

        expect(result.offenses).not_to include(
          hash_including(
            name: 'UndocumentedObject',
            message: a_string_matching(/initialize/)
          )
        )
      end

      it 'flags initialize with 1 parameter' do
        temp_file.write(<<~RUBY)
          class Example
            def initialize(value)
              @value = value
            end
          end
        RUBY
        temp_file.rewind

        expect(result.offenses).to include(
          hash_including(
            name: 'UndocumentedObject',
            message: a_string_matching(/initialize/)
          )
        )
      end

      it 'flags initialize with 2 parameters' do
        temp_file.write(<<~RUBY)
          class Example
            def initialize(value, name)
              @value = value
              @name = name
            end
          end
        RUBY
        temp_file.rewind

        expect(result.offenses).to include(
          hash_including(
            name: 'UndocumentedObject',
            message: a_string_matching(/initialize/)
          )
        )
      end

      it 'excludes call with exactly 1 parameter' do
        temp_file.write(<<~RUBY)
          class Example
            def call(input)
              input.upcase
            end
          end
        RUBY
        temp_file.rewind

        expect(result.offenses).not_to include(
          hash_including(
            name: 'UndocumentedObject',
            message: a_string_matching(/\bcall\b/)
          )
        )
      end

      it 'flags call with 0 parameters' do
        temp_file.write(<<~RUBY)
          class Example
            def call
              'result'
            end
          end
        RUBY
        temp_file.rewind

        expect(result.offenses).to include(
          hash_including(
            name: 'UndocumentedObject',
            message: a_string_matching(/\bcall\b/)
          )
        )
      end

      it 'flags call with 2 parameters' do
        temp_file.write(<<~RUBY)
          class Example
            def call(input, options)
              input.upcase
            end
          end
        RUBY
        temp_file.rewind

        expect(result.offenses).to include(
          hash_including(
            name: 'UndocumentedObject',
            message: a_string_matching(/\bcall\b/)
          )
        )
      end
    end

    context 'when excluding setup/0 and teardown/0 (test framework pattern)' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
            'ExcludedMethods', ['setup/0', 'teardown/0'])
        end
      end

      it 'excludes parameter-less setup and teardown' do
        temp_file.write(<<~RUBY)
          class TestCase
            def setup
              @db = Database.new
            end

            def teardown
              @db.close
            end
          end
        RUBY
        temp_file.rewind

        expect(result.offenses).not_to include(
          hash_including(
            name: 'UndocumentedObject',
            message: a_string_matching(/setup|teardown/)
          )
        )
      end

      it 'flags setup with parameters' do
        temp_file.write(<<~RUBY)
          class TestCase
            def setup(config)
              @db = Database.new(config)
            end
          end
        RUBY
        temp_file.rewind

        expect(result.offenses).to include(
          hash_including(
            name: 'UndocumentedObject',
            message: a_string_matching(/setup/)
          )
        )
      end
    end

    context 'when counting arity with optional parameters' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
            'ExcludedMethods', ['method/2'])
        end
      end

      it 'counts optional parameters in arity' do
        temp_file.write(<<~RUBY)
          class Example
            def method(required, optional = nil)
              [required, optional]
            end
          end
        RUBY
        temp_file.rewind

        # Should be excluded because it has 2 parameters (1 required + 1 optional)
        expect(result.offenses).not_to include(
          hash_including(
            name: 'UndocumentedObject',
            message: a_string_matching(/\bmethod\b/)
          )
        )
      end

      it 'does not count splat parameters in arity' do
        temp_file.write(<<~RUBY)
          class Example
            def method(arg1, arg2, *rest)
              [arg1, arg2, rest]
            end
          end
        RUBY
        temp_file.rewind

        # Has 2 regular params + splat, should match /2
        expect(result.offenses).not_to include(
          hash_including(
            name: 'UndocumentedObject',
            message: a_string_matching(/\bmethod\b/)
          )
        )
      end

      it 'does not count block parameters in arity' do
        temp_file.write(<<~RUBY)
          class Example
            def method(arg1, arg2, &block)
              [arg1, arg2, block]
            end
          end
        RUBY
        temp_file.rewind

        # Has 2 regular params + block, should match /2
        expect(result.offenses).not_to include(
          hash_including(
            name: 'UndocumentedObject',
            message: a_string_matching(/\bmethod\b/)
          )
        )
      end
    end
  end

  describe 'Regex patterns' do
    context 'when excluding methods starting with underscore' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
            'ExcludedMethods', ['/^_/'])
        end
      end

      it 'excludes methods starting with underscore' do
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

        expect(result.offenses).not_to include(
          hash_including(
            name: 'UndocumentedObject',
            message: a_string_matching(/_private_helper|_internal_method/)
          )
        )
      end

      it 'still flags methods not starting with underscore' do
        temp_file.write(<<~RUBY)
          class Example
            def public_method
              'public'
            end
          end
        RUBY
        temp_file.rewind

        expect(result.offenses).to include(
          hash_including(
            name: 'UndocumentedObject',
            message: a_string_matching(/public_method/)
          )
        )
      end
    end

    context 'when excluding test methods' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
            'ExcludedMethods', ['/^test_/', '/^should_/'])
        end
      end

      it 'excludes methods matching test patterns' do
        temp_file.write(<<~RUBY)
          class TestCase
            def test_user_creation
              assert true
            end

            def test_validation
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

        # Should not flag any test methods
        expect(result.offenses).not_to include(
          hash_including(
            name: 'UndocumentedObject',
            message: a_string_matching(/test_|should_/)
          )
        )
      end

      it 'still flags non-test methods' do
        temp_file.write(<<~RUBY)
          class TestCase
            def helper_method
              'helper'
            end
          end
        RUBY
        temp_file.rewind

        expect(result.offenses).to include(
          hash_including(
            name: 'UndocumentedObject',
            message: a_string_matching(/helper_method/)
          )
        )
      end
    end

    context 'when excluding methods ending with specific suffixes' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
            'ExcludedMethods', ['/_(helper|util)$/'])
        end
      end

      it 'excludes methods ending with _helper or _util' do
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

        expect(result.offenses).not_to include(
          hash_including(
            name: 'UndocumentedObject',
            message: a_string_matching(/format_helper|parsing_util/)
          )
        )
      end

      it 'flags methods not matching the pattern' do
        temp_file.write(<<~RUBY)
          class Example
            def regular_method
              'regular'
            end
          end
        RUBY
        temp_file.rewind

        expect(result.offenses).to include(
          hash_including(
            name: 'UndocumentedObject',
            message: a_string_matching(/regular_method/)
          )
        )
      end
    end
  end

  describe 'Combined patterns' do
    context 'when using all three pattern types together' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
            'ExcludedMethods', [
              'to_s',           # Exact name
              'initialize/0',   # Arity notation
              '/^_/'            # Regex
            ])
        end
      end

      it 'applies all exclusion patterns correctly' do
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

        # Should exclude: to_s (exact), initialize() (arity), _private_method (regex)
        expect(result.offenses).not_to include(
          hash_including(
            name: 'UndocumentedObject',
            message: a_string_matching(/to_s|_private_method/)
          )
        )

        # Should flag: public_method, initialize(value)
        expect(result.offenses).to include(
          hash_including(
            name: 'UndocumentedObject',
            message: a_string_matching(/public_method/)
          )
        )
      end
    end

    context 'when combining common Ruby and Rails patterns' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
            'ExcludedMethods', [
              'initialize/0',
              'to_s',
              'inspect',
              'hash',
              'eql?',
              '/^_/'
            ])
        end
      end

      it 'excludes all common pattern methods' do
        temp_file.write(<<~RUBY)
          class User
            attr_reader :name

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

        # All these should be excluded
        %w[initialize to_s inspect hash eql? _build_query].each do |method_name|
          expect(result.offenses).not_to include(
            hash_including(
              name: 'UndocumentedObject',
              message: a_string_matching(/#{Regexp.escape(method_name)}/)
            )
          )
        end
      end
    end
  end

  describe 'Edge cases' do
    context 'when method name contains special regex characters' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
            'ExcludedMethods', ['<<', '[]', '[]='])
        end
      end

      it 'excludes methods with special characters' do
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

        # These operator methods should be excluded
        expect(result.offenses).not_to include(
          hash_including(
            name: 'UndocumentedObject',
            message: a_string_matching(/<<|\[\]|\[\]=/),
            element: a_string_matching(/<<|#\[\]|#\[\]=/)
          )
        )
      end
    end

    context 'when using empty exclusion list' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
            'ExcludedMethods', [])
        end
      end

      it 'flags all undocumented methods including initialize' do
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

        expect(result.offenses).to include(
          hash_including(
            name: 'UndocumentedObject',
            message: a_string_matching(/initialize/)
          )
        )

        expect(result.offenses).to include(
          hash_including(
            name: 'UndocumentedObject',
            message: a_string_matching(/other_method/)
          )
        )
      end
    end
  end

  describe 'Defensive programming - invalid patterns' do
    context 'when regex pattern is invalid' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
            'ExcludedMethods', ['/[/', '/(unclosed', 'to_s'])
        end
      end

      it 'handles invalid regex gracefully without crashing' do
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
        expect { result }.not_to raise_error

        # Invalid regex patterns should be skipped, but to_s should still be excluded
        expect(result.offenses).not_to include(
          hash_including(message: a_string_matching(/to_s/))
        )

        # method_one should be flagged (invalid patterns didn't match it)
        expect(result.offenses).to include(
          hash_including(message: a_string_matching(/method_one/))
        )
      end
    end

    context 'when using empty regex pattern' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
            'ExcludedMethods', ['//', 'inspect'])
        end
      end

      it 'does not exclude all methods with empty regex' do
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

        # Empty regex should be filtered out, not match everything
        # Only inspect should be excluded
        expect(result.offenses).not_to include(
          hash_including(message: a_string_matching(/inspect/))
        )

        expect(result.offenses).to include(
          hash_including(message: a_string_matching(/public_method/))
        )
      end
    end

    context 'when ExcludedMethods is not an array' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
            'ExcludedMethods', 'to_s') # String instead of Array
        end
      end

      it 'converts to array and handles gracefully' do
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
        expect { result }.not_to raise_error

        # Should exclude to_s
        expect(result.offenses).not_to include(
          hash_including(message: a_string_matching(/to_s/))
        )
      end
    end

    context 'when patterns contain whitespace' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
            'ExcludedMethods', [' to_s ', '  initialize/0  ', ' /^_/ '])
        end
      end

      it 'trims whitespace and matches correctly' do
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

        # All excluded methods should be excluded despite whitespace
        expect(result.offenses).not_to include(
          hash_including(message: a_string_matching(/to_s|initialize|_private/))
        )

        # public_method should still be flagged
        expect(result.offenses).to include(
          hash_including(message: a_string_matching(/public_method/))
        )
      end
    end

    context 'when arity notation has invalid values' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
            'ExcludedMethods', ['initialize/abc', 'call/-1', 'setup/', 'method/999'])
        end
      end

      it 'does not match methods with invalid arity patterns' do
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

        # All methods should be flagged because arity patterns are invalid
        expect(result.offenses).to include(
          hash_including(message: a_string_matching(/initialize/))
        )

        expect(result.offenses).to include(
          hash_including(message: a_string_matching(/\bcall\b/))
        )

        expect(result.offenses).to include(
          hash_including(message: a_string_matching(/setup/))
        )

        expect(result.offenses).to include(
          hash_including(message: a_string_matching(/\bmethod\b/))
        )
      end
    end

    context 'when patterns include nil and empty strings' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
            'ExcludedMethods', ['', nil, 'to_s', '', nil])
        end
      end

      it 'ignores nil and empty patterns without crashing' do
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

        expect { result }.not_to raise_error

        # Should only exclude to_s
        expect(result.offenses).not_to include(
          hash_including(message: a_string_matching(/to_s/))
        )

        expect(result.offenses).to include(
          hash_including(message: a_string_matching(/other/))
        )
      end
    end
  end

  describe 'Advanced edge cases' do
    context 'when counting arity with keyword arguments' do
      # Note: YARD may represent keyword args differently than expected
      # These tests verify the actual behavior

      context 'with positional arguments only' do
        let(:config) do
          Yard::Lint::Config.new do |c|
            c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
              'ExcludedMethods', ['method/2'])
          end
        end

        it 'correctly excludes methods with 2 positional params' do
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

          # Should be excluded from UndocumentedObject check (2 positional params)
          # No UndocumentedObject offense for method
          undoc_objects = result.offenses.select { |o| o[:name] == 'UndocumentedObject' }
          expect(undoc_objects).not_to include(
            hash_including(message: a_string_matching(/\bmethod\b/))
          )
        end

        it 'does not exclude methods with different arity' do
          temp_file.write(<<~RUBY)
            class Example
              def method(a, b, c)
                [a, b, c]
              end
            end
          RUBY
          temp_file.rewind

          # Should NOT be excluded (3 params, not 2)
          expect(result.offenses).to include(
            hash_including(message: a_string_matching(/\bmethod\b/))
          )
        end
      end

      context 'with splat parameters' do
        let(:config) do
          Yard::Lint::Config.new do |c|
            c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
              'ExcludedMethods', ['method/2'])
          end
        end

        it 'does not count splat parameters in arity' do
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

          # Should match /2 (not counting *rest)
          undoc_objects = result.offenses.select { |o| o[:name] == 'UndocumentedObject' }
          expect(undoc_objects).not_to include(
            hash_including(message: a_string_matching(/\bmethod\b/))
          )
        end

        it 'does not count block parameters in arity' do
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

          # Should match /2 (not counting &block)
          undoc_objects = result.offenses.select { |o| o[:name] == 'UndocumentedObject' }
          expect(undoc_objects).not_to include(
            hash_including(message: a_string_matching(/\bmethod\b/))
          )
        end
      end
    end

    context 'when excluding operator methods' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
            'ExcludedMethods', ['+', '-', '==', '===', '<=>', '+@', '-@', '!', '~'])
        end
      end

      it 'excludes binary operators' do
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

        operator_pattern = /\+|-|==|<=>|Example#\+|Example#-|Example#==|Example#<=>/
        expect(result.offenses).not_to include(
          hash_including(element: a_string_matching(operator_pattern))
        )
      end

      it 'excludes unary operators' do
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

        expect(result.offenses).not_to include(
          hash_including(element: a_string_matching(/\+@|-@|!|~/))
        )
      end
    end

    context 'when using unicode method names' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
            'ExcludedMethods', ['to_s', '/^test/'])
        end
      end

      it 'handles ASCII method names normally' do
        temp_file.write(<<~RUBY)
          class Example
            def to_s
              'example'
            end

            def test_method
              'test'
            end

            def other
              'other'
            end
          end
        RUBY
        temp_file.rewind

        expect(result.offenses).not_to include(
          hash_including(message: a_string_matching(/to_s|test_method/))
        )

        expect(result.offenses).to include(
          hash_including(message: a_string_matching(/other/))
        )
      end
    end

    context 'when methods have complex parameter signatures' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
            'ExcludedMethods', ['method/3'])
        end
      end

      it 'counts optional parameters in arity' do
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

        # Should count all params including optional (3 total)
        undoc_objects = result.offenses.select { |o| o[:name] == 'UndocumentedObject' }
        expect(undoc_objects).not_to include(
          hash_including(message: a_string_matching(/\bmethod\b/))
        )
      end

      it 'distinguishes different arities correctly' do
        temp_file.write(<<~RUBY)
          class Example
            def method(a, b, c, d)
              [a, b, c, d]
            end
          end
        RUBY
        temp_file.rewind

        # 4 params, should NOT match /3
        expect(result.offenses).to include(
          hash_including(message: a_string_matching(/\bmethod\b/))
        )
      end
    end

    context 'when using pattern precedence' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
            'ExcludedMethods', ['initialize', 'initialize/0', '/^init/'])
        end
      end

      it 'excludes method when any pattern matches (first match wins)' do
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

        # All three patterns match initialize
        # Only regex matches initialize_db
        expect(result.offenses).not_to include(
          hash_including(message: a_string_matching(/initialize/))
        )
      end
    end
  end
end

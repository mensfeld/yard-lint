# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Documentation::MissingReturn::Parser do
  let(:parser) { described_class.new }

  describe '#initialize' do
    it 'inherits from parser base class' do
      expect(parser).to be_a(Yard::Lint::Parsers::Base)
    end
  end

  describe '#call' do
    context 'basic parsing' do
      it 'parses input and returns array' do
        result = parser.call('')
        expect(result).to be_an(Array)
      end

      it 'handles empty input' do
        result = parser.call('')
        expect(result).to eq([])
      end

      it 'parses valid offense line' do
        input = 'lib/example.rb:10: Calculator#add|2'
        result = parser.call(input)

        expect(result).to eq([{
          location: 'lib/example.rb',
          line: 10,
          element: 'Calculator#add'
        }])
      end

      it 'parses multiple offense lines' do
        input = <<~OUTPUT
          lib/example.rb:10: Calculator#add|2
          lib/example.rb:20: Calculator#multiply|2
        OUTPUT

        result = parser.call(input)
        expect(result.size).to eq(2)
        expect(result[0][:element]).to eq('Calculator#add')
        expect(result[1][:element]).to eq('Calculator#multiply')
      end

      it 'parses class methods' do
        input = 'lib/example.rb:5: Calculator.new|1'
        result = parser.call(input)

        expect(result).to eq([{
          location: 'lib/example.rb',
          line: 5,
          element: 'Calculator.new'
        }])
      end

      it 'handles methods with zero arity' do
        input = 'lib/example.rb:15: Calculator#current_value|0'
        result = parser.call(input)

        expect(result).to eq([{
          location: 'lib/example.rb',
          line: 15,
          element: 'Calculator#current_value'
        }])
      end

      it 'skips invalid lines' do
        input = <<~OUTPUT
          lib/example.rb:10: Calculator#add|2
          Invalid line without proper format
          lib/example.rb:20: Calculator#multiply|2
        OUTPUT

        result = parser.call(input)
        expect(result.size).to eq(2)
      end

      it 'handles lines with whitespace' do
        input = "  lib/example.rb:10: Calculator#add|2  \n\n"
        result = parser.call(input)

        expect(result.size).to eq(1)
      end
    end

    context 'config parameter' do
      it 'accepts config keyword argument' do
        config = Yard::Lint::Config.new
        expect { parser.call('', config: config) }.not_to raise_error
      end

      it 'works without config parameter (backwards compatibility)' do
        expect { parser.call('') }.not_to raise_error
      end
    end

    context 'ExcludedMethods filtering' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.send(:set_validator_config, 'Documentation/MissingReturn', 'ExcludedMethods', excluded)
        end
      end

      context 'simple name exclusion' do
        let(:excluded) { ['initialize'] }

        it 'excludes methods matching simple name' do
          input = 'lib/example.rb:5: Example#initialize|1'
          result = parser.call(input, config: config)

          expect(result).to be_empty
        end

        it 'does not exclude methods with different names' do
          input = 'lib/example.rb:10: Example#calculate|0'
          result = parser.call(input, config: config)

          expect(result.size).to eq(1)
        end

        it 'matches simple names with any arity' do
          input = <<~OUTPUT
            lib/example.rb:5: Example#initialize|0
            lib/example.rb:10: Example#initialize|1
            lib/example.rb:15: Example#initialize|2
          OUTPUT

          result = parser.call(input, config: config)
          expect(result).to be_empty
        end
      end

      context 'regex pattern exclusion' do
        let(:excluded) { ['/^_/'] }

        it 'excludes methods matching regex pattern' do
          input = 'lib/example.rb:10: Example#_private_helper|0'
          result = parser.call(input, config: config)

          expect(result).to be_empty
        end

        it 'does not exclude methods not matching pattern' do
          input = 'lib/example.rb:10: Example#public_method|0'
          result = parser.call(input, config: config)

          expect(result.size).to eq(1)
        end

        it 'handles multiple regex patterns' do
          config = Yard::Lint::Config.new do |c|
            c.send(:set_validator_config, 'Documentation/MissingReturn', 'ExcludedMethods', ['/^_/', '/^test_/'])
          end

          input = <<~OUTPUT
            lib/example.rb:5: Example#_helper|0
            lib/example.rb:10: Example#test_something|0
            lib/example.rb:15: Example#regular_method|0
          OUTPUT

          result = parser.call(input, config: config)
          expect(result.size).to eq(1)
          expect(result[0][:element]).to eq('Example#regular_method')
        end

        it 'handles invalid regex gracefully' do
          config = Yard::Lint::Config.new do |c|
            c.send(:set_validator_config, 'Documentation/MissingReturn', 'ExcludedMethods', ['/[invalid/'])
          end

          input = 'lib/example.rb:10: Example#method|0'
          result = parser.call(input, config: config)

          # Invalid regex should be skipped, method should not be excluded
          expect(result.size).to eq(1)
        end

        it 'rejects empty regex patterns' do
          config = Yard::Lint::Config.new do |c|
            c.send(:set_validator_config, 'Documentation/MissingReturn', 'ExcludedMethods', ['//'])
          end

          input = 'lib/example.rb:10: Example#method|0'
          result = parser.call(input, config: config)

          # Empty regex would match everything, so it should be rejected
          expect(result.size).to eq(1)
        end
      end

      context 'arity pattern exclusion' do
        let(:excluded) { ['fetch/1'] }

        it 'excludes methods matching name and arity' do
          input = 'lib/example.rb:10: Cache#fetch|1'
          result = parser.call(input, config: config)

          expect(result).to be_empty
        end

        it 'does not exclude methods with same name but different arity' do
          input = 'lib/example.rb:10: Cache#fetch|2'
          result = parser.call(input, config: config)

          expect(result.size).to eq(1)
        end

        it 'does not exclude methods with different name but same arity' do
          input = 'lib/example.rb:10: Cache#get|1'
          result = parser.call(input, config: config)

          expect(result.size).to eq(1)
        end

        it 'handles zero arity patterns' do
          config = Yard::Lint::Config.new do |c|
            c.send(:set_validator_config, 'Documentation/MissingReturn', 'ExcludedMethods', ['initialize/0'])
          end

          input = <<~OUTPUT
            lib/example.rb:5: Example#initialize|0
            lib/example.rb:10: Example#initialize|1
          OUTPUT

          result = parser.call(input, config: config)
          expect(result.size).to eq(1)
          expect(result[0][:line]).to eq(10)
        end
      end

      context 'mixed exclusion patterns' do
        let(:excluded) { ['initialize', '/^_/', 'fetch/1'] }

        it 'applies all exclusion patterns' do
          input = <<~OUTPUT
            lib/example.rb:5: Example#initialize|0
            lib/example.rb:10: Example#_helper|0
            lib/example.rb:15: Example#fetch|1
            lib/example.rb:20: Example#fetch|2
            lib/example.rb:25: Example#calculate|2
          OUTPUT

          result = parser.call(input, config: config)

          # Should exclude initialize, _helper, fetch/1
          # Should keep fetch/2 and calculate
          expect(result.size).to eq(2)
          expect(result[0][:element]).to eq('Example#fetch')
          expect(result[0][:line]).to eq(20)
          expect(result[1][:element]).to eq('Example#calculate')
        end
      end

      context 'edge cases' do
        it 'handles nil ExcludedMethods' do
          config = Yard::Lint::Config.new do |c|
            c.send(:set_validator_config, 'Documentation/MissingReturn', 'ExcludedMethods', nil)
          end

          input = 'lib/example.rb:10: Example#method|0'
          result = parser.call(input, config: config)

          expect(result.size).to eq(1)
        end

        it 'handles empty ExcludedMethods array' do
          config = Yard::Lint::Config.new do |c|
            c.send(:set_validator_config, 'Documentation/MissingReturn', 'ExcludedMethods', [])
          end

          input = 'lib/example.rb:10: Example#method|0'
          result = parser.call(input, config: config)

          expect(result.size).to eq(1)
        end

        it 'sanitizes patterns with whitespace' do
          config = Yard::Lint::Config.new do |c|
            c.send(:set_validator_config, 'Documentation/MissingReturn', 'ExcludedMethods', ['  initialize  ', '', nil])
          end

          input = <<~OUTPUT
            lib/example.rb:5: Example#initialize|0
            lib/example.rb:10: Example#method|0
          OUTPUT

          result = parser.call(input, config: config)

          # Should exclude initialize (after trimming), method should pass
          expect(result.size).to eq(1)
          expect(result[0][:element]).to eq('Example#method')
        end

        it 'handles class methods with namespaces' do
          config = Yard::Lint::Config.new do |c|
            c.send(:set_validator_config, 'Documentation/MissingReturn', 'ExcludedMethods', ['new'])
          end

          input = 'lib/example.rb:5: Foo::Bar::Baz.new|0'
          result = parser.call(input, config: config)

          expect(result).to be_empty
        end
      end
    end
  end
end

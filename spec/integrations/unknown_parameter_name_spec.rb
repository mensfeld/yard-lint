# frozen_string_literal: true

require 'tempfile'

RSpec.describe 'Unknown Parameter Name Integration' do
  subject(:result) { Yard::Lint.run(path: temp_file.path, progress: false, config: config) }

  let(:temp_file) { Tempfile.new(['test', '.rb']) }
  let(:config) do
    test_config do |c|
      c.send(:set_validator_config, 'Warnings/UnknownParameterName', 'Enabled', true)
    end
  end

  after { temp_file.unlink }

  describe 'detecting unknown parameter names' do
    context 'when @param documents non-existent parameter' do
      before do
        temp_file.write(<<~RUBY)
          # frozen_string_literal: true

          # Test class for unknown parameters
          class TestClass
            # Method with wrong parameter documentation
            # @param current [String] documented but doesn't exist
            # @return [String] the value
            def method_with_wrong_param(value)
              value
            end
          end
        RUBY
        temp_file.rewind
      end

      it 'reports offense with correct file path and line number' do
        offense = result.offenses.find { |o| o[:name] == 'UnknownParameterName' }

        expect(offense).not_to be_nil
        expect(offense[:location]).to eq(temp_file.path)
        expect(offense[:location_line]).to eq(8)  # Line where method is defined
        expect(offense[:message]).to include('current')
      end
    end

    context 'when @param documents splat parameter' do
      before do
        temp_file.write(<<~RUBY)
          # frozen_string_literal: true

          # Test class
          class TestClass
            # Method with splat parameter documentation
            # @param args [Array] the arguments
            # @param ... [Object] additional args (invalid YARD syntax)
            # @return [Array] the arguments
            def method_with_splat(*args)
              args
            end
          end
        RUBY
        temp_file.rewind
      end

      it 'reports offense for ... parameter with correct location' do
        offense = result.offenses.find do |o|
          o[:name] == 'UnknownParameterName' && o[:message].include?('...')
        end

        expect(offense).not_to be_nil
        expect(offense[:location]).to eq(temp_file.path)
        expect(offense[:location_line]).to eq(9)  # Line where method is defined
        expect(offense[:message]).to include('...')
      end
    end

    context 'when method has correct @param tags' do
      before do
        temp_file.write(<<~RUBY)
          # frozen_string_literal: true

          # Test class
          class TestClass
            # Correctly documented method
            # @param value [String] the value
            # @return [String] the value
            def method_with_correct_param(value)
              value
            end
          end
        RUBY
        temp_file.rewind
      end

      it 'does not report any offense' do
        offenses = result.offenses.select { |o| o[:name] == 'UnknownParameterName' }

        expect(offenses).to be_empty
      end
    end

    context 'when documenting *args parameter' do
      before do
        temp_file.write(<<~RUBY)
          # frozen_string_literal: true

          # Test class
          class TestClass
            # Method with invalid *args documentation
            # @param *args [Array] the arguments (invalid syntax)
            # @return [Array] the arguments
            def method_with_splat(*args)
              args
            end
          end
        RUBY
        temp_file.rewind
      end

      it 'reports offense for *args parameter name with correct location' do
        offense = result.offenses.find do |o|
          o[:name] == 'UnknownParameterName' && o[:message].include?('*args')
        end

        expect(offense).not_to be_nil
        expect(offense[:location]).to eq(temp_file.path)
        expect(offense[:location_line]).to eq(8)  # Line where method is defined
        expect(offense[:message]).to include('*args')
      end
    end
  end

  describe 'location reporting' do
    before do
      temp_file.write(<<~RUBY)
        # frozen_string_literal: true

        # Test class with multiple unknown parameters
        class TestClass
          # First method
          # @param wrong1 [String] wrong param
          def first_method(value1)
            value1
          end

          # Second method
          # @param wrong2 [String] wrong param
          def second_method(value2)
            value2
          end

          # Third method
          # @param wrong3 [String] wrong param
          def third_method(value3)
            value3
          end
        end
      RUBY
      temp_file.rewind
    end

    it 'reports all offenses with correct file paths (not just line numbers)' do
      offenses = result.offenses.select { |o| o[:name] == 'UnknownParameterName' }

      expect(offenses.size).to eq(3)

      # All offenses should have the full file path, not empty or nil
      offenses.each do |offense|
        expect(offense[:location]).to eq(temp_file.path)
        expect(offense[:location]).not_to be_empty
        expect(offense[:location]).not_to be_nil
        expect(offense[:location_line]).to be > 0
      end

      # Verify specific line numbers (where methods are defined)
      expect(offenses.map { |o| o[:location_line] }).to contain_exactly(7, 13, 19)
    end
  end
end

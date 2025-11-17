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

  describe '"did you mean" suggestions' do
    context 'when parameter name is a typo' do
      before do
        temp_file.write(<<~RUBY)
          # frozen_string_literal: true

          # Test class
          class TestClass
            # Method with typo in parameter documentation
            # @param user_nme [String] typo in parameter name
            # @return [String] the user name
            def process(user_name)
              user_name
            end
          end
        RUBY
        temp_file.rewind
      end

      it 'suggests the correct parameter name' do
        offense = result.offenses.find { |o| o[:name] == 'UnknownParameterName' }

        expect(offense).not_to be_nil
        expect(offense[:message]).to include('user_nme')
        expect(offense[:message]).to include("did you mean 'user_name'?")
      end
    end

    context 'when parameter name changed during refactoring' do
      before do
        temp_file.write(<<~RUBY)
          # frozen_string_literal: true

          # Test class
          class TestClass
            # Method that was refactored
            # @param old_value [String] old parameter name from before refactoring
            # @param old_count [Integer] another old parameter
            # @return [String] result
            def process(new_value, new_count)
              "\#{new_value}\#{new_count}"
            end
          end
        RUBY
        temp_file.rewind
      end

      it 'suggests the most similar parameter for first mismatch' do
        offenses = result.offenses.select { |o| o[:name] == 'UnknownParameterName' }

        expect(offenses.size).to eq(2)

        old_value_offense = offenses.find { |o| o[:message].include?('old_value') }
        expect(old_value_offense[:message]).to include("did you mean 'new_value'?")
      end

      it 'suggests the most similar parameter for second mismatch' do
        offenses = result.offenses.select { |o| o[:name] == 'UnknownParameterName' }

        old_count_offense = offenses.find { |o| o[:message].include?('old_count') }
        expect(old_count_offense[:message]).to include("did you mean 'new_count'?")
      end
    end

    context 'when parameter name is completely different' do
      before do
        temp_file.write(<<~RUBY)
          # frozen_string_literal: true

          # Test class
          class TestClass
            # Method with completely different parameter
            # @param xyz [String] completely unrelated name
            # @return [String] the value
            def process(value)
              value
            end
          end
        RUBY
        temp_file.rewind
      end

      it 'does not suggest when parameters are too different' do
        offense = result.offenses.find { |o| o[:name] == 'UnknownParameterName' }

        expect(offense).not_to be_nil
        expect(offense[:message]).to include('xyz')
        expect(offense[:message]).not_to include('did you mean')
      end
    end

    context 'when method has multiple parameters' do
      before do
        temp_file.write(<<~RUBY)
          # frozen_string_literal: true

          # Test class
          class TestClass
            # Method with multiple parameters
            # @param usr [String] typo
            # @param email [String] correct
            # @param age [Integer] correct
            # @return [String] result
            def process(user, email, age)
              "\#{user} \#{email} \#{age}"
            end
          end
        RUBY
        temp_file.rewind
      end

      it 'suggests the closest matching parameter' do
        offense = result.offenses.find { |o| o[:name] == 'UnknownParameterName' }

        expect(offense).not_to be_nil
        expect(offense[:message]).to include('usr')
        expect(offense[:message]).to include("did you mean 'user'?")
      end
    end

    context 'with keyword arguments' do
      before do
        temp_file.write(<<~RUBY)
          # frozen_string_literal: true

          # Test class
          class TestClass
            # Method with keyword arguments
            # @param nam [String] typo in keyword argument
            # @param emai [String] typo in keyword argument
            # @return [String] result
            def process(name:, email:)
              "\#{name} \#{email}"
            end
          end
        RUBY
        temp_file.rewind
      end

      it 'suggests correct keyword parameter names' do
        offenses = result.offenses.select { |o| o[:name] == 'UnknownParameterName' }

        expect(offenses.size).to eq(2)

        nam_offense = offenses.find { |o| o[:message].include?('nam') }
        expect(nam_offense[:message]).to include("did you mean 'name'?")

        emai_offense = offenses.find { |o| o[:message].include?('emai') }
        expect(emai_offense[:message]).to include("did you mean 'email'?")
      end
    end

    context 'with splat and block parameters' do
      before do
        temp_file.write(<<~RUBY)
          # frozen_string_literal: true

          # Test class
          class TestClass
            # Method with various parameter types
            # @param nam [String] typo
            # @param arg [Array] typo (should be args)
            # @param kwarg [Hash] typo (should be kwargs)
            # @return [String] result
            def process(name, *args, **kwargs, &block)
              name
            end
          end
        RUBY
        temp_file.rewind
      end

      it 'suggests parameter names without special characters' do
        offenses = result.offenses.select { |o| o[:name] == 'UnknownParameterName' }

        arg_offense = offenses.find { |o| o[:message].include?('arg') && !o[:message].include?('kwarg') }
        expect(arg_offense).not_to be_nil
        expect(arg_offense[:message]).to include("did you mean 'args'?")

        kwarg_offense = offenses.find { |o| o[:message].include?('kwarg') }
        expect(kwarg_offense).not_to be_nil
        expect(kwarg_offense[:message]).to include("did you mean 'kwargs'?")
      end
    end
  end
end

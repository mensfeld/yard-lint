# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Warnings::UnknownParameterName::MessagesBuilder do
  describe '.call' do
    let(:messages_builder) { described_class }

    context 'when offense has no message' do
      it 'returns default message' do
        offense = { location: '/tmp/test.rb', line: 10 }
        result = messages_builder.call(offense)
        expect(result).to eq('UnknownParameterName detected')
      end
    end

    context 'when message does not match expected format' do
      it 'returns the message as-is' do
        offense = { message: 'Some other error', location: '/tmp/test.rb', line: 10 }
        result = messages_builder.call(offense)
        expect(result).to eq('Some other error')
      end
    end

    context 'when message matches unknown parameter format' do
      let(:test_file) { Tempfile.new(['test', '.rb']) }

      before do
        test_file.write(<<~RUBY)
          class TestClass
            # Test method
            # @param old_name [String] wrong param
            def process(new_name)
              new_name
            end
          end
        RUBY
        test_file.close
      end

      after { test_file.unlink }

      it 'adds did you mean suggestion for similar parameter' do
        offense = {
          message: '@param tag has unknown parameter name: old_name',
          location: test_file.path,
          line: 4
        }
        result = messages_builder.call(offense)
        expect(result).to eq("@param tag has unknown parameter name: old_name (did you mean 'new_name'?)")
      end

      it 'handles multiple similar parameters' do
        test_file2 = Tempfile.new(['test2', '.rb'])
        test_file2.write(<<~RUBY)
          class TestClass
            # Test method
            # @param user_nme [String] typo
            def process(user_name, user_email)
              user_name
            end
          end
        RUBY
        test_file2.close

        offense = {
          message: '@param tag has unknown parameter name: user_nme',
          location: test_file2.path,
          line: 4
        }
        result = messages_builder.call(offense)
        expect(result).to include("did you mean 'user_name'?")

        test_file2.unlink
      end

      it 'returns original message when no similar parameters found' do
        test_file3 = Tempfile.new(['test3', '.rb'])
        test_file3.write(<<~RUBY)
          class TestClass
            # Test method
            # @param completely_different [String] no match
            def process(foo)
              foo
            end
          end
        RUBY
        test_file3.close

        offense = {
          message: '@param tag has unknown parameter name: completely_different',
          location: test_file3.path,
          line: 4
        }
        result = messages_builder.call(offense)
        # Should not have suggestion since parameters are too different
        expect(result).to eq('@param tag has unknown parameter name: completely_different')

        test_file3.unlink
      end

      it 'returns original message when file does not exist' do
        offense = {
          message: '@param tag has unknown parameter name: old_name',
          location: '/nonexistent/file.rb',
          line: 10
        }
        result = messages_builder.call(offense)
        expect(result).to eq('@param tag has unknown parameter name: old_name')
      end

      it 'handles methods with no parameters' do
        test_file4 = Tempfile.new(['test4', '.rb'])
        test_file4.write(<<~RUBY)
          class TestClass
            # Test method
            # @param wrong [String] should not be here
            def process
              true
            end
          end
        RUBY
        test_file4.close

        offense = {
          message: '@param tag has unknown parameter name: wrong',
          location: test_file4.path,
          line: 4
        }
        result = messages_builder.call(offense)
        expect(result).to eq('@param tag has unknown parameter name: wrong')

        test_file4.unlink
      end
    end
  end

  describe 'parameter extraction' do
    let(:messages_builder) { described_class }

    it 'extracts simple parameters' do
      params = messages_builder.send(:extract_parameter_names, 'name, email')
      expect(params).to eq(%w[name email])
    end

    it 'extracts parameters with default values' do
      params = messages_builder.send(:extract_parameter_names, "name, email = 'default'")
      expect(params).to eq(%w[name email])
    end

    it 'extracts keyword parameters' do
      params = messages_builder.send(:extract_parameter_names, 'name:, email:')
      expect(params).to eq(%w[name email])
    end

    it 'extracts splat parameters' do
      params = messages_builder.send(:extract_parameter_names, 'name, *args, **kwargs, &block')
      expect(params).to eq(%w[name args kwargs block])
    end

    it 'handles empty parameter string' do
      params = messages_builder.send(:extract_parameter_names, '')
      expect(params).to eq([])
    end
  end

  describe 'Levenshtein distance' do
    let(:messages_builder) { described_class }

    it 'calculates distance between identical strings' do
      distance = messages_builder.send(:levenshtein_distance, 'hello', 'hello')
      expect(distance).to eq(0)
    end

    it 'calculates distance between different strings' do
      distance = messages_builder.send(:levenshtein_distance, 'kitten', 'sitting')
      expect(distance).to eq(3)
    end

    it 'calculates distance with empty string' do
      distance = messages_builder.send(:levenshtein_distance, '', 'hello')
      expect(distance).to eq(5)

      distance = messages_builder.send(:levenshtein_distance, 'hello', '')
      expect(distance).to eq(5)
    end
  end

  describe 'suggestion finder' do
    let(:messages_builder) { described_class }

    it 'finds best match using Levenshtein distance' do
      suggestion = messages_builder.send(:find_suggestion, 'user_nme', %w[user_name user_email])
      expect(suggestion).to eq('user_name')
    end

    it 'returns nil when no good match exists' do
      suggestion = messages_builder.send(:find_suggestion, 'xyz', %w[abc def ghi])
      expect(suggestion).to be_nil
    end

    it 'returns nil when parameters list is empty' do
      suggestion = messages_builder.send(:find_suggestion, 'param', [])
      expect(suggestion).to be_nil
    end

    it 'uses DidYouMean when available and has suggestions' do
      # DidYouMean is very conservative, so test with a close typo
      suggestion = messages_builder.send(:find_suggestion, 'proces', %w[process])
      expect(suggestion).not_to be_nil
    end
  end
end

# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Validators::Warnings::UnknownParameterName::MessagesBuilder' do
  attr_reader :messages_builder

  before do
    @messages_builder = Yard::Lint::Validators::Warnings::UnknownParameterName::MessagesBuilder
  end

  it 'call when offense has no message returns default message' do
    offense = { location: '/tmp/test.rb', line: 10 }
    result = messages_builder.call(offense)
    assert_equal('UnknownParameterName detected', result)
  end

  it 'call when message does not match expected format returns the message as is' do
    offense = { message: 'Some other error', location: '/tmp/test.rb', line: 10 }
    result = messages_builder.call(offense)
    assert_equal('Some other error', result)
  end

  it 'call when message matches unknown parameter format adds did you mean suggestion for similar parameter' do
    test_file = Tempfile.new(['test', '.rb'])

    begin
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

      offense = {
        message: '@param tag has unknown parameter name: old_name',
        location: test_file.path,
        line: 4
      }
      result = messages_builder.call(offense)
      assert_equal("@param tag has unknown parameter name: old_name (did you mean 'new_name'?)", result)
    ensure
      test_file.close unless test_file.closed?
      test_file.unlink
    end
  end

  it 'call when message matches unknown parameter format handles multiple similar parameters' do
    test_file2 = Tempfile.new(['test2', '.rb'])

    begin
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
      assert_includes(result, "did you mean 'user_name'?")
    ensure
      test_file2.close unless test_file2.closed?
      test_file2.unlink
    end
  end

  it 'call returns original message when no similar parameters found' do
    test_file3 = Tempfile.new(['test3', '.rb'])

    begin
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
      assert_equal('@param tag has unknown parameter name: completely_different', result)
    ensure
      test_file3.close unless test_file3.closed?
      test_file3.unlink
    end
  end

  it 'call returns original message when file does not exist' do
    offense = {
      message: '@param tag has unknown parameter name: old_name',
      location: '/nonexistent/file.rb',
      line: 10
    }
    result = messages_builder.call(offense)
    assert_equal('@param tag has unknown parameter name: old_name', result)
  end

  it 'call handles methods with no parameters' do
    test_file4 = Tempfile.new(['test4', '.rb'])

    begin
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
      assert_equal('@param tag has unknown parameter name: wrong', result)
    ensure
      test_file4.close unless test_file4.closed?
      test_file4.unlink
    end
  end

  it 'parameter extraction extracts simple parameters' do
    params = messages_builder.send(:extract_parameter_names, 'name, email')
    assert_equal(%w[name email], params)
  end

  it 'parameter extraction extracts parameters with default values' do
    params = messages_builder.send(:extract_parameter_names, "name, email = 'default'")
    assert_equal(%w[name email], params)
  end

  it 'parameter extraction extracts keyword parameters' do
    params = messages_builder.send(:extract_parameter_names, 'name:, email:')
    assert_equal(%w[name email], params)
  end

  it 'parameter extraction extracts splat parameters' do
    params = messages_builder.send(:extract_parameter_names, 'name, *args, **kwargs, &block')
    assert_equal(%w[name args kwargs block], params)
  end

  it 'parameter extraction handles empty parameter string' do
    params = messages_builder.send(:extract_parameter_names, '')
    assert_equal([], params)
  end

  it 'levenshtein distance calculates distance between identical strings' do
    distance = messages_builder.send(:levenshtein_distance, 'hello', 'hello')
    assert_equal(0, distance)
  end

  it 'levenshtein distance calculates distance between different strings' do
    distance = messages_builder.send(:levenshtein_distance, 'kitten', 'sitting')
    assert_equal(3, distance)
  end

  it 'levenshtein distance calculates distance with empty string' do
    distance = messages_builder.send(:levenshtein_distance, '', 'hello')
    assert_equal(5, distance)

    distance = messages_builder.send(:levenshtein_distance, 'hello', '')
    assert_equal(5, distance)
  end

  it 'suggestion finder finds best match using levenshtein distance' do
    suggestion = messages_builder.send(:find_suggestion, 'user_nme', %w[user_name user_email])
    assert_equal('user_name', suggestion)
  end

  it 'suggestion finder returns nil when no good match exists' do
    suggestion = messages_builder.send(:find_suggestion, 'xyz', %w[abc def ghi])
    assert_nil(suggestion)
  end

  it 'suggestion finder returns nil when parameters list is empty' do
    suggestion = messages_builder.send(:find_suggestion, 'param', [])
    assert_nil(suggestion)
  end

  it 'suggestion finder uses didyoumean when available and has suggestions' do
    # DidYouMean is very conservative, so test with a close typo
    suggestion = messages_builder.send(:find_suggestion, 'proces', %w[process])
    refute_nil(suggestion)
  end
end


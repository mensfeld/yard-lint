# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsWarningsUnknownParameterNameMessagesBuilderTest < Minitest::Test

  attr_reader :messages_builder

  def setup
    @messages_builder = Yard::Lint::Validators::Warnings::UnknownParameterName::MessagesBuilder
  end

  def test_call_when_offense_has_no_message_returns_default_message
    offense = { location: '/tmp/test.rb', line: 10 }
    result = messages_builder.call(offense)
    assert_equal('UnknownParameterName detected', result)
  end

  def test_call_when_message_does_not_match_expected_format_returns_the_message_as_is
    offense = { message: 'Some other error', location: '/tmp/test.rb', line: 10 }
    result = messages_builder.call(offense)
    assert_equal('Some other error', result)
  end

  def test_call_when_message_matches_unknown_parameter_format_adds_did_you_mean_suggestion_for_similar_parameter
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

  def test_call_when_message_matches_unknown_parameter_format_handles_multiple_similar_parameters
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

  def test_call_returns_original_message_when_no_similar_parameters_found
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

  def test_call_returns_original_message_when_file_does_not_exist
    offense = {
      message: '@param tag has unknown parameter name: old_name',
      location: '/nonexistent/file.rb',
      line: 10
    }
    result = messages_builder.call(offense)
    assert_equal('@param tag has unknown parameter name: old_name', result)
  end

  def test_call_handles_methods_with_no_parameters
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

  def test_parameter_extraction_extracts_simple_parameters
    params = messages_builder.send(:extract_parameter_names, 'name, email')
    assert_equal(%w[name email], params)
  end

  def test_parameter_extraction_extracts_parameters_with_default_values
    params = messages_builder.send(:extract_parameter_names, "name, email = 'default'")
    assert_equal(%w[name email], params)
  end

  def test_parameter_extraction_extracts_keyword_parameters
    params = messages_builder.send(:extract_parameter_names, 'name:, email:')
    assert_equal(%w[name email], params)
  end

  def test_parameter_extraction_extracts_splat_parameters
    params = messages_builder.send(:extract_parameter_names, 'name, *args, **kwargs, &block')
    assert_equal(%w[name args kwargs block], params)
  end

  def test_parameter_extraction_handles_empty_parameter_string
    params = messages_builder.send(:extract_parameter_names, '')
    assert_equal([], params)
  end

  def test_levenshtein_distance_calculates_distance_between_identical_strings
    distance = messages_builder.send(:levenshtein_distance, 'hello', 'hello')
    assert_equal(0, distance)
  end

  def test_levenshtein_distance_calculates_distance_between_different_strings
    distance = messages_builder.send(:levenshtein_distance, 'kitten', 'sitting')
    assert_equal(3, distance)
  end

  def test_levenshtein_distance_calculates_distance_with_empty_string
    distance = messages_builder.send(:levenshtein_distance, '', 'hello')
    assert_equal(5, distance)

    distance = messages_builder.send(:levenshtein_distance, 'hello', '')
    assert_equal(5, distance)
  end

  def test_suggestion_finder_finds_best_match_using_levenshtein_distance
    suggestion = messages_builder.send(:find_suggestion, 'user_nme', %w[user_name user_email])
    assert_equal('user_name', suggestion)
  end

  def test_suggestion_finder_returns_nil_when_no_good_match_exists
    suggestion = messages_builder.send(:find_suggestion, 'xyz', %w[abc def ghi])
    assert_nil(suggestion)
  end

  def test_suggestion_finder_returns_nil_when_parameters_list_is_empty
    suggestion = messages_builder.send(:find_suggestion, 'param', [])
    assert_nil(suggestion)
  end

  def test_suggestion_finder_uses_didyoumean_when_available_and_has_suggestions
    # DidYouMean is very conservative, so test with a close typo
    suggestion = messages_builder.send(:find_suggestion, 'proces', %w[process])
    refute_nil(suggestion)
  end
end

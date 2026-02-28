# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsWarningsUnknownTagMessagesBuilderTest < Minitest::Test

  attr_reader :messages_builder

  def setup
    @messages_builder = Yard::Lint::Validators::Warnings::UnknownTag::MessagesBuilder
  end

  def test_call_when_offense_has_no_message_returns_default_message
    offense = { location: '/tmp/test.rb', line: 10 }
    result = messages_builder.call(offense)
    assert_equal('Unknown tag detected', result)
  end

  def test_call_when_message_does_not_match_expected_format_returns_the_message_as_is
    offense = { message: 'Some other error', location: '/tmp/test.rb', line: 10 }
    result = messages_builder.call(offense)
    assert_equal('Some other error', result)
  end

  def test_call_when_message_matches_unknown_tag_format_adds_did_you_mean_suggestion_for_returns
    offense = {
      message: 'Unknown tag @returns in file `/tmp/test.rb` near line 10',
      location: '/tmp/test.rb',
      line: 10
    }
    result = messages_builder.call(offense)
    assert_equal("Unknown tag @returns (did you mean '@return'?) in file `/tmp/test.rb` near line 10", result)
  end

  def test_call_when_message_matches_unknown_tag_format_adds_did_you_mean_suggestion_for_raises
    offense = {
      message: 'Unknown tag @raises in file `/tmp/test.rb` near line 15',
      location: '/tmp/test.rb',
      line: 15
    }
    result = messages_builder.call(offense)
    assert_equal("Unknown tag @raises (did you mean '@raise'?) in file `/tmp/test.rb` near line 15", result)
  end

  def test_call_when_message_matches_unknown_tag_format_adds_did_you_mean_suggestion_for_params
    offense = {
      message: 'Unknown tag @params in file `/tmp/test.rb` near line 20',
      location: '/tmp/test.rb',
      line: 20
    }
    result = messages_builder.call(offense)
    assert_equal("Unknown tag @params (did you mean '@param'?) in file `/tmp/test.rb` near line 20", result)
  end

  def test_call_when_message_matches_unknown_tag_format_adds_did_you_mean_suggestion_for_exampl
    offense = {
      message: 'Unknown tag @exampl in file `/tmp/test.rb` near line 25',
      location: '/tmp/test.rb',
      line: 25
    }
    result = messages_builder.call(offense)
    assert_equal("Unknown tag @exampl (did you mean '@example'?) in file `/tmp/test.rb` near line 25", result)
  end

  def test_call_when_message_matches_unknown_tag_format_adds_did_you_mean_suggestion_for_auhtor
    offense = {
      message: 'Unknown tag @auhtor in file `/tmp/test.rb` near line 30',
      location: '/tmp/test.rb',
      line: 30
    }
    result = messages_builder.call(offense)
    assert_equal("Unknown tag @auhtor (did you mean '@author'?) in file `/tmp/test.rb` near line 30", result)
  end

  def test_call_when_message_matches_unknown_tag_format_adds_did_you_mean_suggestion_for_deprected
    offense = {
      message: 'Unknown tag @deprected in file `/tmp/test.rb` near line 35',
      location: '/tmp/test.rb',
      line: 35
    }
    result = messages_builder.call(offense)
    assert_equal("Unknown tag @deprected (did you mean '@deprecated'?) in file `/tmp/test.rb` near line 35", result)
  end

  def test_call_when_message_matches_unknown_tag_format_returns_original_message_when_no_similar_tag_found
    offense = {
      message: 'Unknown tag @completelywrong in file `/tmp/test.rb` near line 40',
      location: '/tmp/test.rb',
      line: 40
    }
    result = messages_builder.call(offense)
    assert_equal('Unknown tag @completelywrong in file `/tmp/test.rb` near line 40', result)
  end

  def test_call_when_message_matches_unknown_tag_format_returns_original_message_when_tag_is_too_different
    offense = {
      message: 'Unknown tag @xyz in file `/tmp/test.rb` near line 45',
      location: '/tmp/test.rb',
      line: 45
    }
    result = messages_builder.call(offense)
    assert_equal('Unknown tag @xyz in file `/tmp/test.rb` near line 45', result)
  end

  def test_known_tags_includes_standard_yard_meta_data_tags
    tags = Yard::Lint::Validators::Warnings::UnknownTag::MessagesBuilder.known_tags
    assert_includes(tags, 'param')
    assert_includes(tags, 'return')
    assert_includes(tags, 'raise')
    assert_includes(tags, 'example')
    assert_includes(tags, 'author')
  end

  def test_known_tags_returns_tags_dynamically_from_yard_tags_library
    assert_operator(Yard::Lint::Validators::Warnings::UnknownTag::MessagesBuilder.known_tags.size, :>=, 22)
  end

  def test_known_tags_all_tags_are_lowercase_strings
    Yard::Lint::Validators::Warnings::UnknownTag::MessagesBuilder.known_tags.each do |tag|
      assert_kind_of(String, tag)
      assert_equal(tag.downcase, tag)
    end
  end

  def test_known_tags_caches_the_result
    first_call = Yard::Lint::Validators::Warnings::UnknownTag::MessagesBuilder.known_tags
    second_call = Yard::Lint::Validators::Warnings::UnknownTag::MessagesBuilder.known_tags
    assert_equal(first_call.object_id, second_call.object_id)
  end

  def test_known_directives_includes_standard_yard_directives
    directives = Yard::Lint::Validators::Warnings::UnknownTag::MessagesBuilder.known_directives
    assert_includes(directives, 'attribute')
    assert_includes(directives, 'method')
    assert_includes(directives, 'macro')
  end

  def test_known_directives_returns_directives_dynamically_from_yard_tags_library
    assert_operator(Yard::Lint::Validators::Warnings::UnknownTag::MessagesBuilder.known_directives.size, :>=, 8)
  end

  def test_known_directives_all_directives_are_lowercase_strings
    Yard::Lint::Validators::Warnings::UnknownTag::MessagesBuilder.known_directives.each do |directive|
      assert_kind_of(String, directive)
      assert_equal(directive.downcase, directive)
    end
  end

  def test_known_directives_caches_the_result
    first_call = Yard::Lint::Validators::Warnings::UnknownTag::MessagesBuilder.known_directives
    second_call = Yard::Lint::Validators::Warnings::UnknownTag::MessagesBuilder.known_directives
    assert_equal(first_call.object_id, second_call.object_id)
  end

  def test_all_known_tags_combines_tags_and_directives
    expected_size = Yard::Lint::Validators::Warnings::UnknownTag::MessagesBuilder.known_tags.size +
                    Yard::Lint::Validators::Warnings::UnknownTag::MessagesBuilder.known_directives.size
    assert_equal(expected_size, Yard::Lint::Validators::Warnings::UnknownTag::MessagesBuilder.all_known_tags.size)
  end

  def test_all_known_tags_includes_both_tags_and_directives
    all_tags = Yard::Lint::Validators::Warnings::UnknownTag::MessagesBuilder.all_known_tags
    assert_includes(all_tags, 'param')
    assert_includes(all_tags, 'attribute')
  end

  def test_all_known_tags_caches_the_result
    first_call = Yard::Lint::Validators::Warnings::UnknownTag::MessagesBuilder.all_known_tags
    second_call = Yard::Lint::Validators::Warnings::UnknownTag::MessagesBuilder.all_known_tags
    assert_equal(first_call.object_id, second_call.object_id)
  end

  def test_levenshtein_distance_calculates_distance_between_identical_strings
    distance = messages_builder.send(:levenshtein_distance, 'hello', 'hello')
    assert_equal(0, distance)
  end

  def test_levenshtein_distance_calculates_distance_for_returns_vs_return
    distance = messages_builder.send(:levenshtein_distance, 'returns', 'return')
    assert_equal(1, distance)
  end

  def test_levenshtein_distance_calculates_distance_for_raises_vs_raise
    distance = messages_builder.send(:levenshtein_distance, 'raises', 'raise')
    assert_equal(1, distance)
  end

  def test_levenshtein_distance_calculates_distance_with_empty_string
    distance = messages_builder.send(:levenshtein_distance, '', 'hello')
    assert_equal(5, distance)

    distance = messages_builder.send(:levenshtein_distance, 'hello', '')
    assert_equal(5, distance)
  end

  def test_suggestion_finder_finds_best_match_for_returns
    suggestion = messages_builder.send(:find_suggestion, 'returns')
    assert_equal('return', suggestion)
  end

  def test_suggestion_finder_finds_best_match_for_raises
    suggestion = messages_builder.send(:find_suggestion, 'raises')
    assert_equal('raise', suggestion)
  end

  def test_suggestion_finder_finds_best_match_for_params
    suggestion = messages_builder.send(:find_suggestion, 'params')
    assert_equal('param', suggestion)
  end

  def test_suggestion_finder_finds_best_match_for_exampl
    suggestion = messages_builder.send(:find_suggestion, 'exampl')
    assert_equal('example', suggestion)
  end

  def test_suggestion_finder_finds_best_match_for_auhtor
    suggestion = messages_builder.send(:find_suggestion, 'auhtor')
    assert_equal('author', suggestion)
  end

  def test_suggestion_finder_finds_best_match_for_deprected
    suggestion = messages_builder.send(:find_suggestion, 'deprected')
    assert_equal('deprecated', suggestion)
  end

  def test_suggestion_finder_returns_nil_when_no_good_match_exists
    suggestion = messages_builder.send(:find_suggestion, 'xyz')
    assert_nil(suggestion)
  end

  def test_suggestion_finder_returns_nil_when_tag_name_is_empty
    suggestion = messages_builder.send(:find_suggestion, '')
    assert_nil(suggestion)
  end

  def test_suggestion_finder_uses_didyoumean_when_available
    # DidYouMean is very good at detecting common typos
    suggestion = messages_builder.send(:find_suggestion, 'retur')
    assert_equal('return', suggestion)
  end

  def test_suggestion_finder_finds_directive_suggestions
    suggestion = messages_builder.send(:find_suggestion, 'attribut')
    assert_equal('attribute', suggestion)
  end

  def test_fallback_suggestion_finder_finds_suggestion_using_levenshtein_distance
    suggestion = messages_builder.send(:find_suggestion_fallback, 'returns')
    assert_equal('return', suggestion)
  end

  def test_fallback_suggestion_finder_returns_nil_for_very_different_strings
    suggestion = messages_builder.send(:find_suggestion_fallback, 'completelydifferent')
    assert_nil(suggestion)
  end

  def test_fallback_suggestion_finder_respects_distance_threshold
    # Should not suggest when distance is more than half the length
    suggestion = messages_builder.send(:find_suggestion_fallback, 'xxxxxxx')
    assert_nil(suggestion)
  end
end

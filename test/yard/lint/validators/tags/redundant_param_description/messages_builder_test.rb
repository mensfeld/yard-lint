# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsRedundantParamDescriptionMessagesBuilderTest < Minitest::Test

  def test_call_with_article_param_pattern_returns_message_about_restating_parameter_name
    offense = {
      tag_name: 'param',
      param_name: 'appointment',
      description: 'The appointment',
      pattern_type: 'article_param'
    }
    message = Yard::Lint::Validators::Tags::RedundantParamDescription::MessagesBuilder.call(offense)
    assert_includes(message, 'redundant')
    assert_includes(message, 'restates the parameter name')
    assert_includes(message, 'The appointment')
    assert_includes(message, '@param appointment [Type]')
  end

  def test_call_with_article_param_pattern_includes_tag_name_in_message
    offense = {
      tag_name: 'param',
      param_name: 'appointment',
      description: 'The appointment',
      pattern_type: 'article_param'
    }
    message = Yard::Lint::Validators::Tags::RedundantParamDescription::MessagesBuilder.call(offense)
    assert_includes(message, '@param')
  end

  def test_call_with_possessive_param_pattern_returns_message_about_no_meaningful_information
    offense = {
      tag_name: 'param',
      param_name: 'appointment',
      description: "The event's appointment",
      pattern_type: 'possessive_param'
    }
    message = Yard::Lint::Validators::Tags::RedundantParamDescription::MessagesBuilder.call(offense)
    assert_includes(message, 'adds no meaningful information')
    assert_includes(message, "The event's appointment")
    assert_includes(message, "parameter's specific purpose")
  end

  def test_call_with_type_restatement_pattern_returns_message_about_repeating_type_name
    offense = {
      tag_name: 'param',
      param_name: 'user',
      description: 'User object',
      pattern_type: 'type_restatement'
    }
    message = Yard::Lint::Validators::Tags::RedundantParamDescription::MessagesBuilder.call(offense)
    assert_includes(message, 'repeats the type name')
    assert_includes(message, 'User object')
    assert_includes(message, 'removing the description or explaining what makes this user significant')
  end

  def test_call_with_param_to_verb_pattern_returns_message_about_being_too_generic
    offense = {
      tag_name: 'param',
      param_name: 'payments',
      description: 'Payments to count',
      pattern_type: 'param_to_verb'
    }
    message = Yard::Lint::Validators::Tags::RedundantParamDescription::MessagesBuilder.call(offense)
    assert_includes(message, 'too generic')
    assert_includes(message, 'Payments to count')
    assert_includes(message, 'what the payments is used for in detail')
  end

  def test_call_with_id_pattern_pattern_returns_message_about_self_explanatory_parameter_name
    offense = {
      tag_name: 'param',
      param_name: 'treatment_id',
      description: 'ID of the treatment',
      pattern_type: 'id_pattern'
    }
    message = Yard::Lint::Validators::Tags::RedundantParamDescription::MessagesBuilder.call(offense)
    assert_includes(message, 'self-explanatory')
    assert_includes(message, 'ID of the treatment')
    assert_includes(message, '@param treatment_id [Type]')
  end

  def test_call_with_directional_date_pattern_returns_message_about_parameter_name_already_indicating_meaning
    offense = {
      tag_name: 'param',
      param_name: 'from',
      description: 'from this date',
      pattern_type: 'directional_date'
    }
    message = Yard::Lint::Validators::Tags::RedundantParamDescription::MessagesBuilder.call(offense)
    assert_includes(message, 'redundant')
    assert_includes(message, 'parameter name already indicates')
    assert_includes(message, 'from this date')
    assert_includes(message, "date's specific meaning")
  end

  def test_call_with_type_generic_pattern_returns_message_about_combining_type_and_generic_terms
    offense = {
      tag_name: 'param',
      param_name: 'payment',
      description: 'Payment object',
      pattern_type: 'type_generic'
    }
    message = Yard::Lint::Validators::Tags::RedundantParamDescription::MessagesBuilder.call(offense)
    assert_includes(message, 'combines type and generic terms')
    assert_includes(message, 'Payment object')
    assert_includes(message, 'specific details about this payment')
  end

  def test_call_with_article_param_phrase_pattern_returns_message_about_filler_phrase
    offense = {
      tag_name: 'param',
      param_name: 'action',
      description: 'The action being performed',
      pattern_type: 'article_param_phrase'
    }
    message = Yard::Lint::Validators::Tags::RedundantParamDescription::MessagesBuilder.call(offense)
    assert_includes(message, 'filler phrase')
    assert_includes(message, 'adds no value')
    assert_includes(message, 'The action being performed')
    assert_includes(message, 'specific purpose of action')
  end

  def test_call_with_unknown_pattern_type_returns_generic_redundant_message
    offense = {
      tag_name: 'param',
      param_name: 'data',
      description: 'Some data',
      pattern_type: 'unknown_pattern'
    }
    message = Yard::Lint::Validators::Tags::RedundantParamDescription::MessagesBuilder.call(offense)
    assert_includes(message, 'appears redundant')
    assert_includes(message, 'Some data')
    assert_includes(message, 'meaningful description or omitting it')
  end

  def test_call_with_option_tag_uses_option_in_message
    offense = {
      tag_name: 'option',
      param_name: 'name',
      description: 'The name',
      pattern_type: 'article_param'
    }
    message = Yard::Lint::Validators::Tags::RedundantParamDescription::MessagesBuilder.call(offense)
    assert_includes(message, '@option')
    assert_includes(message, '@option name [Type]')
  end

  def test_call_when_validating_message_content_article_param_suggests_removing_description
    offense = {
      tag_name: 'param',
      param_name: 'user',
      description: 'The user',
      pattern_type: 'article_param'
    }
    message = Yard::Lint::Validators::Tags::RedundantParamDescription::MessagesBuilder.call(offense)
    assert_includes(message, 'Consider removing the description')
  end

  def test_call_when_validating_message_content_possessive_param_suggests_explaining_purpose
    offense = {
      tag_name: 'param',
      param_name: 'user',
      description: "The system's user",
      pattern_type: 'possessive_param'
    }
    message = Yard::Lint::Validators::Tags::RedundantParamDescription::MessagesBuilder.call(offense)
    assert_includes(message, 'removing it or explaining')
  end

  def test_call_when_validating_message_content_type_restatement_suggests_explanation
    offense = {
      tag_name: 'param',
      param_name: 'value',
      description: 'Integer value',
      pattern_type: 'type_restatement'
    }
    message = Yard::Lint::Validators::Tags::RedundantParamDescription::MessagesBuilder.call(offense)
    assert_includes(message, 'removing the description or explaining')
  end

  def test_call_when_checking_all_messages_include_the_original_description
    patterns = %w[
      article_param possessive_param type_restatement
      param_to_verb id_pattern directional_date type_generic
      article_param_phrase
    ]

    patterns.each do |pattern|
      offense = {
        tag_name: 'param',
        param_name: 'test',
        description: 'Test description',
        pattern_type: pattern
      }
      message = Yard::Lint::Validators::Tags::RedundantParamDescription::MessagesBuilder.call(offense)
      assert_includes(message, 'Test description')
    end
  end

  def test_call_when_checking_all_messages_provide_actionable_suggestions
    patterns = %w[
      article_param possessive_param type_restatement
      param_to_verb id_pattern directional_date type_generic
      article_param_phrase
    ]

    patterns.each do |pattern|
      offense = {
        tag_name: 'param',
        param_name: 'test',
        description: 'Test description',
        pattern_type: pattern
      }
      message = Yard::Lint::Validators::Tags::RedundantParamDescription::MessagesBuilder.call(offense)
      assert_match(/[Cc]onsider/, message)
    end
  end
end

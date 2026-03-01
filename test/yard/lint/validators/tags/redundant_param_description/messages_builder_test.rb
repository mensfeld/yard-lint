# frozen_string_literal: true

require 'test_helper'


describe 'Yard::Lint::Validators::Tags::RedundantParamDescription::MessagesBuilder' do
  it 'call with article param pattern returns message about restating parameter name' do
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

  it 'call with article param pattern includes tag name in message' do
    offense = {
      tag_name: 'param',
      param_name: 'appointment',
      description: 'The appointment',
      pattern_type: 'article_param'
    }
    message = Yard::Lint::Validators::Tags::RedundantParamDescription::MessagesBuilder.call(offense)
    assert_includes(message, '@param')
  end

  it 'call with possessive param pattern returns message about no meaningful information' do
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

  it 'call with type restatement pattern returns message about repeating type name' do
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

  it 'call with param to verb pattern returns message about being too generic' do
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

  it 'call with id pattern pattern returns message about self explanatory parameter name' do
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

  it 'call with directional date pattern returns message about parameter name already indicating meaning' do
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

  it 'call with type generic pattern returns message about combining type and generic terms' do
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

  it 'call with article param phrase pattern returns message about filler phrase' do
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

  it 'call with unknown pattern type returns generic redundant message' do
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

  it 'call with option tag uses option in message' do
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

  it 'call when validating message content article param suggests removing description' do
    offense = {
      tag_name: 'param',
      param_name: 'user',
      description: 'The user',
      pattern_type: 'article_param'
    }
    message = Yard::Lint::Validators::Tags::RedundantParamDescription::MessagesBuilder.call(offense)
    assert_includes(message, 'Consider removing the description')
  end

  it 'call when validating message content possessive param suggests explaining purpose' do
    offense = {
      tag_name: 'param',
      param_name: 'user',
      description: "The system's user",
      pattern_type: 'possessive_param'
    }
    message = Yard::Lint::Validators::Tags::RedundantParamDescription::MessagesBuilder.call(offense)
    assert_includes(message, 'removing it or explaining')
  end

  it 'call when validating message content type restatement suggests explanation' do
    offense = {
      tag_name: 'param',
      param_name: 'value',
      description: 'Integer value',
      pattern_type: 'type_restatement'
    }
    message = Yard::Lint::Validators::Tags::RedundantParamDescription::MessagesBuilder.call(offense)
    assert_includes(message, 'removing the description or explaining')
  end

  it 'call when checking all messages include the original description' do
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

  it 'call when checking all messages provide actionable suggestions' do
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

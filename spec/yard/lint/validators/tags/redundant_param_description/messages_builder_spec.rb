# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::RedundantParamDescription::MessagesBuilder do
  describe '.call' do
    context 'with article_param pattern' do
      let(:offense) do
        {
          tag_name: 'param',
          param_name: 'appointment',
          description: 'The appointment',
          pattern_type: 'article_param'
        }
      end

      it 'returns message about restating parameter name' do
        message = described_class.call(offense)
        expect(message).to include('redundant')
        expect(message).to include('restates the parameter name')
        expect(message).to include('The appointment')
        expect(message).to include('@param appointment [Type]')
      end

      it 'includes tag name in message' do
        message = described_class.call(offense)
        expect(message).to include('@param')
      end
    end

    context 'with possessive_param pattern' do
      let(:offense) do
        {
          tag_name: 'param',
          param_name: 'appointment',
          description: "The event's appointment",
          pattern_type: 'possessive_param'
        }
      end

      it 'returns message about no meaningful information' do
        message = described_class.call(offense)
        expect(message).to include('adds no meaningful information')
        expect(message).to include("The event's appointment")
        expect(message).to include("parameter's specific purpose")
      end
    end

    context 'with type_restatement pattern' do
      let(:offense) do
        {
          tag_name: 'param',
          param_name: 'user',
          description: 'User object',
          pattern_type: 'type_restatement'
        }
      end

      it 'returns message about repeating type name' do
        message = described_class.call(offense)
        expect(message).to include('repeats the type name')
        expect(message).to include('User object')
        expect(message).to include('removing the description or explaining what makes this user significant')
      end
    end

    context 'with param_to_verb pattern' do
      let(:offense) do
        {
          tag_name: 'param',
          param_name: 'payments',
          description: 'Payments to count',
          pattern_type: 'param_to_verb'
        }
      end

      it 'returns message about being too generic' do
        message = described_class.call(offense)
        expect(message).to include('too generic')
        expect(message).to include('Payments to count')
        expect(message).to include('what the payments is used for in detail')
      end
    end

    context 'with id_pattern pattern' do
      let(:offense) do
        {
          tag_name: 'param',
          param_name: 'treatment_id',
          description: 'ID of the treatment',
          pattern_type: 'id_pattern'
        }
      end

      it 'returns message about self-explanatory parameter name' do
        message = described_class.call(offense)
        expect(message).to include('self-explanatory')
        expect(message).to include('ID of the treatment')
        expect(message).to include('@param treatment_id [Type]')
      end
    end

    context 'with directional_date pattern' do
      let(:offense) do
        {
          tag_name: 'param',
          param_name: 'from',
          description: 'from this date',
          pattern_type: 'directional_date'
        }
      end

      it 'returns message about parameter name already indicating meaning' do
        message = described_class.call(offense)
        expect(message).to include('redundant')
        expect(message).to include('parameter name already indicates')
        expect(message).to include('from this date')
        expect(message).to include("date's specific meaning")
      end
    end

    context 'with type_generic pattern' do
      let(:offense) do
        {
          tag_name: 'param',
          param_name: 'payment',
          description: 'Payment object',
          pattern_type: 'type_generic'
        }
      end

      it 'returns message about combining type and generic terms' do
        message = described_class.call(offense)
        expect(message).to include('combines type and generic terms')
        expect(message).to include('Payment object')
        expect(message).to include('specific details about this payment')
      end
    end

    context 'with article_param_phrase pattern' do
      let(:offense) do
        {
          tag_name: 'param',
          param_name: 'action',
          description: 'The action being performed',
          pattern_type: 'article_param_phrase'
        }
      end

      it 'returns message about filler phrase' do
        message = described_class.call(offense)
        expect(message).to include('filler phrase')
        expect(message).to include('adds no value')
        expect(message).to include('The action being performed')
        expect(message).to include('specific purpose of action')
      end
    end

    context 'with unknown pattern type' do
      let(:offense) do
        {
          tag_name: 'param',
          param_name: 'data',
          description: 'Some data',
          pattern_type: 'unknown_pattern'
        }
      end

      it 'returns generic redundant message' do
        message = described_class.call(offense)
        expect(message).to include('appears redundant')
        expect(message).to include('Some data')
        expect(message).to include('meaningful description or omitting it')
      end
    end

    context 'with @option tag' do
      let(:offense) do
        {
          tag_name: 'option',
          param_name: 'name',
          description: 'The name',
          pattern_type: 'article_param'
        }
      end

      it 'uses @option in message' do
        message = described_class.call(offense)
        expect(message).to include('@option')
        expect(message).to include('@option name [Type]')
      end
    end

    context 'when validating message content' do
      it 'article_param suggests removing description' do
        offense = {
          tag_name: 'param',
          param_name: 'user',
          description: 'The user',
          pattern_type: 'article_param'
        }
        message = described_class.call(offense)
        expect(message).to include('Consider removing the description')
      end

      it 'possessive_param suggests explaining purpose' do
        offense = {
          tag_name: 'param',
          param_name: 'user',
          description: "The system's user",
          pattern_type: 'possessive_param'
        }
        message = described_class.call(offense)
        expect(message).to include('removing it or explaining')
      end

      it 'type_restatement suggests explanation' do
        offense = {
          tag_name: 'param',
          param_name: 'value',
          description: 'Integer value',
          pattern_type: 'type_restatement'
        }
        message = described_class.call(offense)
        expect(message).to include('removing the description or explaining')
      end
    end

    context 'when checking all messages' do
      it 'include the original description' do
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
          message = described_class.call(offense)
          expect(message).to include('Test description')
        end
      end

      it 'provide actionable suggestions' do
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
          message = described_class.call(offense)
          expect(message).to match(/[Cc]onsider/)
        end
      end
    end
  end
end

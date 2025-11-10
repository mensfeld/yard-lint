# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::RedundantParamDescription::Result do
  let(:config) { Yard::Lint::Config.new }

  describe 'class attributes' do
    it 'has correct default severity' do
      expect(described_class.default_severity).to eq('convention')
    end

    it 'has correct offense type' do
      expect(described_class.offense_type).to eq('tag')
    end

    it 'has correct offense name' do
      expect(described_class.offense_name).to eq('RedundantParamDescription')
    end
  end

  describe '#initialize' do
    it 'inherits from Base result' do
      result = described_class.new([], config)
      expect(result).to be_a(Yard::Lint::Results::Base)
    end

    it 'stores config' do
      result = described_class.new([], config)
      expect(result.config).to eq(config)
    end
  end

  describe 'offense building' do
    context 'with no violations' do
      it 'returns empty offenses array' do
        result = described_class.new([], config)
        expect(result.offenses).to eq([])
      end
    end

    context 'with single violation' do
      let(:parsed_data) do
        [{
          name: 'RedundantParamDescription',
          tag_name: 'param',
          param_name: 'user',
          description: 'The user',
          type_name: 'User',
          pattern_type: 'article_param',
          word_count: 2,
          location: 'lib/example.rb',
          line: 10,
          object_name: 'MyClass#method'
        }]
      end

      it 'returns offense with all required fields' do
        result = described_class.new(parsed_data, config)
        offense = result.offenses.first

        expect(offense[:name]).to eq('RedundantParamDescription')
        expect(offense[:location]).to eq('lib/example.rb')
        expect(offense[:location_line]).to eq(10)
        expect(offense[:severity]).to eq('convention')
        expect(offense[:message]).to be_a(String)
        expect(offense[:message]).to include('The user')
      end

      it 'includes pattern-specific message' do
        result = described_class.new(parsed_data, config)
        message = result.offenses.first[:message]

        expect(message).to include('redundant')
        expect(message).to include('restates the parameter name')
      end

      it 'preserves object name in offense' do
        result = described_class.new(parsed_data, config)
        offense = result.offenses.first

        expect(offense[:object_name]).to eq('MyClass#method')
      end
    end

    context 'with multiple violations' do
      let(:parsed_data) do
        [
          {
            name: 'RedundantParamDescription',
            tag_name: 'param',
            param_name: 'user',
            description: 'The user',
            type_name: 'User',
            pattern_type: 'article_param',
            word_count: 2,
            location: 'lib/example.rb',
            line: 10,
            object_name: 'MyClass#method1'
          },
          {
            name: 'RedundantParamDescription',
            tag_name: 'param',
            param_name: 'data',
            description: 'The data',
            type_name: 'Hash',
            pattern_type: 'article_param',
            word_count: 2,
            location: 'lib/example.rb',
            line: 20,
            object_name: 'MyClass#method2'
          },
          {
            name: 'RedundantParamDescription',
            tag_name: 'param',
            param_name: 'payment',
            description: 'Payment object',
            type_name: 'Payment',
            pattern_type: 'type_restatement',
            word_count: 2,
            location: 'lib/other.rb',
            line: 30,
            object_name: 'OtherClass#process'
          }
        ]
      end

      it 'returns all offenses' do
        result = described_class.new(parsed_data, config)
        expect(result.offenses.length).to eq(3)
      end

      it 'parses each offense correctly' do
        result = described_class.new(parsed_data, config)
        offenses = result.offenses

        expect(offenses[0][:location_line]).to eq(10)
        expect(offenses[0][:location]).to eq('lib/example.rb')
        expect(offenses[0][:object_name]).to eq('MyClass#method1')

        expect(offenses[1][:location_line]).to eq(20)
        expect(offenses[1][:location]).to eq('lib/example.rb')

        expect(offenses[2][:location_line]).to eq(30)
        expect(offenses[2][:location]).to eq('lib/other.rb')
      end
    end

    context 'with different pattern types' do
      let(:parsed_data) do
        [
          {
            name: 'RedundantParamDescription',
            tag_name: 'param',
            param_name: 'appointment',
            description: 'The appointment',
            type_name: 'Appointment',
            pattern_type: 'article_param',
            word_count: 2,
            location: 'lib/example.rb',
            line: 10,
            object_name: 'MyClass#method1'
          },
          {
            name: 'RedundantParamDescription',
            tag_name: 'param',
            param_name: 'appointment',
            description: "The event's appointment",
            type_name: 'Appointment',
            pattern_type: 'possessive_param',
            word_count: 3,
            location: 'lib/example.rb',
            line: 20,
            object_name: 'MyClass#method2'
          },
          {
            name: 'RedundantParamDescription',
            tag_name: 'param',
            param_name: 'user',
            description: 'User object',
            type_name: 'User',
            pattern_type: 'type_restatement',
            word_count: 2,
            location: 'lib/example.rb',
            line: 30,
            object_name: 'MyClass#method3'
          }
        ]
      end

      it 'generates different messages for different patterns' do
        result = described_class.new(parsed_data, config)
        messages = result.offenses.map { |o| o[:message] }

        expect(messages[0]).to include('restates the parameter name')
        expect(messages[1]).to include('adds no meaningful information')
        expect(messages[2]).to include('repeats the type name')
      end
    end
  end

  describe 'severity' do
    it 'defaults to convention' do
      parsed_data = [{
        name: 'RedundantParamDescription',
        tag_name: 'param',
        param_name: 'user',
        description: 'The user',
        type_name: 'User',
        pattern_type: 'article_param',
        word_count: 2,
        location: 'lib/example.rb',
        line: 10,
        object_name: 'MyClass#method'
      }]

      result = described_class.new(parsed_data, config)
      expect(result.offenses.first[:severity]).to eq('convention')
    end
  end

  describe 'offense structure' do
    let(:parsed_data) do
      [{
        name: 'RedundantParamDescription',
        tag_name: 'param',
        param_name: 'user',
        description: 'The user',
        type_name: 'User',
        pattern_type: 'article_param',
        word_count: 2,
        location: 'lib/example.rb',
        line: 10,
        object_name: 'MyClass#method'
      }]
    end

    it 'includes all required offense keys' do
      result = described_class.new(parsed_data, config)
      offense = result.offenses.first

      expect(offense).to have_key(:name)
      expect(offense).to have_key(:location)
      expect(offense).to have_key(:location_line)
      expect(offense).to have_key(:severity)
      expect(offense).to have_key(:message)
      expect(offense).to have_key(:object_name)
    end

    it 'has correct offense name' do
      result = described_class.new(parsed_data, config)
      expect(result.offenses.first[:name]).to eq('RedundantParamDescription')
    end
  end
end

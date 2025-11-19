# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Warnings::UnknownTag::MessagesBuilder do
  describe '.call' do
    let(:messages_builder) { described_class }

    context 'when offense has no message' do
      it 'returns default message' do
        offense = { location: '/tmp/test.rb', line: 10 }
        result = messages_builder.call(offense)
        expect(result).to eq('Unknown tag detected')
      end
    end

    context 'when message does not match expected format' do
      it 'returns the message as-is' do
        offense = { message: 'Some other error', location: '/tmp/test.rb', line: 10 }
        result = messages_builder.call(offense)
        expect(result).to eq('Some other error')
      end
    end

    context 'when message matches unknown tag format' do
      it 'adds did you mean suggestion for @returns' do
        offense = {
          message: 'Unknown tag @returns in file `/tmp/test.rb` near line 10',
          location: '/tmp/test.rb',
          line: 10
        }
        result = messages_builder.call(offense)
        expect(result).to eq("Unknown tag @returns (did you mean '@return'?) in file `/tmp/test.rb` near line 10")
      end

      it 'adds did you mean suggestion for @raises' do
        offense = {
          message: 'Unknown tag @raises in file `/tmp/test.rb` near line 15',
          location: '/tmp/test.rb',
          line: 15
        }
        result = messages_builder.call(offense)
        expect(result).to eq("Unknown tag @raises (did you mean '@raise'?) in file `/tmp/test.rb` near line 15")
      end

      it 'adds did you mean suggestion for @params' do
        offense = {
          message: 'Unknown tag @params in file `/tmp/test.rb` near line 20',
          location: '/tmp/test.rb',
          line: 20
        }
        result = messages_builder.call(offense)
        expect(result).to eq("Unknown tag @params (did you mean '@param'?) in file `/tmp/test.rb` near line 20")
      end

      it 'adds did you mean suggestion for @exampl' do
        offense = {
          message: 'Unknown tag @exampl in file `/tmp/test.rb` near line 25',
          location: '/tmp/test.rb',
          line: 25
        }
        result = messages_builder.call(offense)
        expect(result).to eq("Unknown tag @exampl (did you mean '@example'?) in file `/tmp/test.rb` near line 25")
      end

      it 'adds did you mean suggestion for @auhtor' do
        offense = {
          message: 'Unknown tag @auhtor in file `/tmp/test.rb` near line 30',
          location: '/tmp/test.rb',
          line: 30
        }
        result = messages_builder.call(offense)
        expect(result).to eq("Unknown tag @auhtor (did you mean '@author'?) in file `/tmp/test.rb` near line 30")
      end

      it 'adds did you mean suggestion for @deprected' do
        offense = {
          message: 'Unknown tag @deprected in file `/tmp/test.rb` near line 35',
          location: '/tmp/test.rb',
          line: 35
        }
        result = messages_builder.call(offense)
        expect(result).to eq("Unknown tag @deprected (did you mean '@deprecated'?) in file `/tmp/test.rb` near line 35")
      end

      it 'returns original message when no similar tag found' do
        offense = {
          message: 'Unknown tag @completelywrong in file `/tmp/test.rb` near line 40',
          location: '/tmp/test.rb',
          line: 40
        }
        result = messages_builder.call(offense)
        expect(result).to eq('Unknown tag @completelywrong in file `/tmp/test.rb` near line 40')
      end

      it 'returns original message when tag is too different' do
        offense = {
          message: 'Unknown tag @xyz in file `/tmp/test.rb` near line 45',
          location: '/tmp/test.rb',
          line: 45
        }
        result = messages_builder.call(offense)
        expect(result).to eq('Unknown tag @xyz in file `/tmp/test.rb` near line 45')
      end
    end
  end

  describe '.known_tags' do
    it 'includes standard YARD meta-data tags' do
      expect(described_class.known_tags).to include('param', 'return', 'raise', 'example', 'author')
    end

    it 'returns tags dynamically from YARD::Tags::Library' do
      expect(described_class.known_tags.size).to be >= 22
    end

    it 'all tags are lowercase strings' do
      expect(described_class.known_tags).to all(be_a(String))
      expect(described_class.known_tags).to all(satisfy { |tag| tag == tag.downcase })
    end

    it 'caches the result' do
      first_call = described_class.known_tags
      second_call = described_class.known_tags
      expect(first_call.object_id).to eq(second_call.object_id)
    end
  end

  describe '.known_directives' do
    it 'includes standard YARD directives' do
      expect(described_class.known_directives).to include('attribute', 'method', 'macro')
    end

    it 'returns directives dynamically from YARD::Tags::Library' do
      expect(described_class.known_directives.size).to be >= 8
    end

    it 'all directives are lowercase strings' do
      expect(described_class.known_directives).to all(be_a(String))
      expect(described_class.known_directives).to all(satisfy { |directive| directive == directive.downcase })
    end

    it 'caches the result' do
      first_call = described_class.known_directives
      second_call = described_class.known_directives
      expect(first_call.object_id).to eq(second_call.object_id)
    end
  end

  describe '.all_known_tags' do
    it 'combines tags and directives' do
      expected_size = described_class.known_tags.size + described_class.known_directives.size
      expect(described_class.all_known_tags.size).to eq(expected_size)
    end

    it 'includes both tags and directives' do
      expect(described_class.all_known_tags).to include('param', 'attribute')
    end

    it 'caches the result' do
      first_call = described_class.all_known_tags
      second_call = described_class.all_known_tags
      expect(first_call.object_id).to eq(second_call.object_id)
    end
  end

  describe 'Levenshtein distance' do
    let(:messages_builder) { described_class }

    it 'calculates distance between identical strings' do
      distance = messages_builder.send(:levenshtein_distance, 'hello', 'hello')
      expect(distance).to eq(0)
    end

    it 'calculates distance for @returns vs @return' do
      distance = messages_builder.send(:levenshtein_distance, 'returns', 'return')
      expect(distance).to eq(1)
    end

    it 'calculates distance for @raises vs @raise' do
      distance = messages_builder.send(:levenshtein_distance, 'raises', 'raise')
      expect(distance).to eq(1)
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

    it 'finds best match for @returns' do
      suggestion = messages_builder.send(:find_suggestion, 'returns')
      expect(suggestion).to eq('return')
    end

    it 'finds best match for @raises' do
      suggestion = messages_builder.send(:find_suggestion, 'raises')
      expect(suggestion).to eq('raise')
    end

    it 'finds best match for @params' do
      suggestion = messages_builder.send(:find_suggestion, 'params')
      expect(suggestion).to eq('param')
    end

    it 'finds best match for @exampl' do
      suggestion = messages_builder.send(:find_suggestion, 'exampl')
      expect(suggestion).to eq('example')
    end

    it 'finds best match for @auhtor' do
      suggestion = messages_builder.send(:find_suggestion, 'auhtor')
      expect(suggestion).to eq('author')
    end

    it 'finds best match for @deprected' do
      suggestion = messages_builder.send(:find_suggestion, 'deprected')
      expect(suggestion).to eq('deprecated')
    end

    it 'returns nil when no good match exists' do
      suggestion = messages_builder.send(:find_suggestion, 'xyz')
      expect(suggestion).to be_nil
    end

    it 'returns nil when tag name is empty' do
      suggestion = messages_builder.send(:find_suggestion, '')
      expect(suggestion).to be_nil
    end

    it 'uses DidYouMean when available' do
      # DidYouMean is very good at detecting common typos
      suggestion = messages_builder.send(:find_suggestion, 'retur')
      expect(suggestion).to eq('return')
    end

    it 'finds directive suggestions' do
      suggestion = messages_builder.send(:find_suggestion, 'attribut')
      expect(suggestion).to eq('attribute')
    end
  end

  describe 'fallback suggestion finder' do
    let(:messages_builder) { described_class }

    it 'finds suggestion using Levenshtein distance' do
      suggestion = messages_builder.send(:find_suggestion_fallback, 'returns')
      expect(suggestion).to eq('return')
    end

    it 'returns nil for very different strings' do
      suggestion = messages_builder.send(:find_suggestion_fallback, 'completelydifferent')
      expect(suggestion).to be_nil
    end

    it 'respects distance threshold' do
      # Should not suggest when distance is more than half the length
      suggestion = messages_builder.send(:find_suggestion_fallback, 'xxxxxxx')
      expect(suggestion).to be_nil
    end
  end
end

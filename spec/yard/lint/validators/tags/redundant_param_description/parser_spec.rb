# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::RedundantParamDescription::Parser do
  let(:parser) { described_class.new }

  describe '#initialize' do
    it 'inherits from parser base class' do
      expect(parser).to be_a(Yard::Lint::Parsers::Base)
    end
  end

  describe '#call' do
    it 'parses input and returns array' do
      result = parser.call('')
      expect(result).to be_an(Array)
    end

    it 'handles empty input' do
      result = parser.call('')
      expect(result).to eq([])
    end

    it 'handles nil input' do
      result = parser.call(nil)
      expect(result).to eq([])
    end

    it 'parses article_param pattern correctly' do
      output = <<~OUTPUT
        lib/example.rb:10: MyClass#method
        param|appointment|The appointment|Appointment|article_param|2
      OUTPUT

      result = parser.call(output)
      expect(result).to eq(
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
            object_name: 'MyClass#method'
          }
        ]
      )
    end

    it 'parses possessive_param pattern correctly' do
      output = <<~OUTPUT
        lib/example.rb:15: MyClass#process
        param|appointment|The event's appointment|Appointment|possessive_param|3
      OUTPUT

      result = parser.call(output)
      expect(result.length).to eq(1)
      expect(result[0][:pattern_type]).to eq('possessive_param')
      expect(result[0][:description]).to eq("The event's appointment")
    end

    it 'parses type_restatement pattern correctly' do
      output = <<~OUTPUT
        lib/example.rb:20: MyClass#execute
        param|user|User object|User|type_restatement|2
      OUTPUT

      result = parser.call(output)
      expect(result.length).to eq(1)
      expect(result[0][:pattern_type]).to eq('type_restatement')
      expect(result[0][:description]).to eq('User object')
    end

    it 'parses param_to_verb pattern correctly' do
      output = <<~OUTPUT
        lib/example.rb:25: MyClass#run
        param|payments|Payments to count|Array|param_to_verb|3
      OUTPUT

      result = parser.call(output)
      expect(result.length).to eq(1)
      expect(result[0][:pattern_type]).to eq('param_to_verb')
    end

    it 'parses id_pattern correctly' do
      output = <<~OUTPUT
        lib/example.rb:30: MyClass#find
        param|treatment_id|ID of the treatment|String|id_pattern|4
      OUTPUT

      result = parser.call(output)
      expect(result.length).to eq(1)
      expect(result[0][:pattern_type]).to eq('id_pattern')
    end

    it 'parses directional_date pattern correctly' do
      output = <<~OUTPUT
        lib/example.rb:35: MyClass#filter
        param|from|from this date|Date|directional_date|3
      OUTPUT

      result = parser.call(output)
      expect(result.length).to eq(1)
      expect(result[0][:pattern_type]).to eq('directional_date')
    end

    it 'parses type_generic pattern correctly' do
      output = <<~OUTPUT
        lib/example.rb:40: MyClass#create
        param|payment|Payment object|Payment|type_generic|2
      OUTPUT

      result = parser.call(output)
      expect(result.length).to eq(1)
      expect(result[0][:pattern_type]).to eq('type_generic')
    end

    it 'parses multiple violations' do
      output = <<~OUTPUT
        lib/example.rb:10: MyClass#method1
        param|user|The user|User|article_param|2
        lib/example.rb:20: MyClass#method2
        param|data|The data|Hash|article_param|2
      OUTPUT

      result = parser.call(output)
      expect(result.length).to eq(2)
      expect(result[0][:param_name]).to eq('user')
      expect(result[1][:param_name]).to eq('data')
    end

    it 'handles violations without type name' do
      output = <<~OUTPUT
        lib/example.rb:10: MyClass#method
        param|data|The data||article_param|2
      OUTPUT

      result = parser.call(output)
      expect(result.length).to eq(1)
      expect(result[0][:type_name]).to be_nil
    end

    it 'ignores lines that do not match location pattern' do
      output = <<~OUTPUT
        random text
        lib/example.rb:10: MyClass#method
        param|user|The user|User|article_param|2
      OUTPUT

      result = parser.call(output)
      expect(result.length).to eq(1)
      expect(result[0][:param_name]).to eq('user')
    end
  end
end

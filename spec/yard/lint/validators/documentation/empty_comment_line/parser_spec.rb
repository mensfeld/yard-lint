# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Yard::Lint::Validators::Documentation::EmptyCommentLine::Parser do
  let(:parser) { described_class.new }

  describe '#call' do
    context 'with leading violations' do
      it 'parses single leading violation' do
        output = <<~OUTPUT
          lib/example.rb:10: MyClass#process
          leading:5
        OUTPUT

        result = parser.call(output)

        expect(result).to eq(
          [
            {
              location: 'lib/example.rb',
              line: 5,
              object_line: 10,
              object_name: 'MyClass#process',
              violation_type: 'leading'
            }
          ]
        )
      end
    end

    context 'with trailing violations' do
      it 'parses single trailing violation' do
        output = <<~OUTPUT
          lib/example.rb:10: MyClass#process
          trailing:9
        OUTPUT

        result = parser.call(output)

        expect(result).to eq(
          [
            {
              location: 'lib/example.rb',
              line: 9,
              object_line: 10,
              object_name: 'MyClass#process',
              violation_type: 'trailing'
            }
          ]
        )
      end
    end

    context 'with both leading and trailing violations' do
      it 'parses multiple violations for same object' do
        output = <<~OUTPUT
          lib/example.rb:10: MyClass#process
          leading:5|trailing:9
        OUTPUT

        result = parser.call(output)

        expect(result).to eq(
          [
            {
              location: 'lib/example.rb',
              line: 5,
              object_line: 10,
              object_name: 'MyClass#process',
              violation_type: 'leading'
            },
            {
              location: 'lib/example.rb',
              line: 9,
              object_line: 10,
              object_name: 'MyClass#process',
              violation_type: 'trailing'
            }
          ]
        )
      end
    end

    context 'with multiple objects' do
      it 'parses violations for multiple objects' do
        output = <<~OUTPUT
          lib/example.rb:10: MyClass#process
          leading:5
          lib/example.rb:20: MyClass#execute
          trailing:19
        OUTPUT

        result = parser.call(output)

        expect(result).to eq(
          [
            {
              location: 'lib/example.rb',
              line: 5,
              object_line: 10,
              object_name: 'MyClass#process',
              violation_type: 'leading'
            },
            {
              location: 'lib/example.rb',
              line: 19,
              object_line: 20,
              object_name: 'MyClass#execute',
              violation_type: 'trailing'
            }
          ]
        )
      end
    end

    context 'with multiple leading empty lines' do
      it 'parses multiple leading violations' do
        output = <<~OUTPUT
          lib/example.rb:10: MyClass#process
          leading:5|leading:6
        OUTPUT

        result = parser.call(output)

        expect(result).to eq(
          [
            {
              location: 'lib/example.rb',
              line: 5,
              object_line: 10,
              object_name: 'MyClass#process',
              violation_type: 'leading'
            },
            {
              location: 'lib/example.rb',
              line: 6,
              object_line: 10,
              object_name: 'MyClass#process',
              violation_type: 'leading'
            }
          ]
        )
      end
    end

    context 'with empty output' do
      it 'returns empty array for empty string' do
        result = parser.call('')
        expect(result).to eq([])
      end

      it 'returns empty array for nil' do
        result = parser.call(nil)
        expect(result).to eq([])
      end
    end
  end
end

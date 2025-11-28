# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Yard::Lint::Validators::Documentation::BlankLineBeforeDefinition::Parser do
  let(:parser) { described_class.new }

  describe '#call' do
    context 'with single blank line violation' do
      it 'parses single blank line violation' do
        output = <<~OUTPUT
          lib/example.rb:10: MyClass#process
          single:1
        OUTPUT

        result = parser.call(output)

        expect(result).to eq(
          [
            {
              location: 'lib/example.rb',
              line: 10,
              object_name: 'MyClass#process',
              violation_type: 'single',
              blank_count: 1
            }
          ]
        )
      end
    end

    context 'with orphaned documentation violation' do
      it 'parses orphaned docs violation with 2 blank lines' do
        output = <<~OUTPUT
          lib/example.rb:15: MyClass#execute
          orphaned:2
        OUTPUT

        result = parser.call(output)

        expect(result).to eq(
          [
            {
              location: 'lib/example.rb',
              line: 15,
              object_name: 'MyClass#execute',
              violation_type: 'orphaned',
              blank_count: 2
            }
          ]
        )
      end

      it 'parses orphaned docs violation with 3 blank lines' do
        output = <<~OUTPUT
          lib/example.rb:20: MyClass#run
          orphaned:3
        OUTPUT

        result = parser.call(output)

        expect(result).to eq(
          [
            {
              location: 'lib/example.rb',
              line: 20,
              object_name: 'MyClass#run',
              violation_type: 'orphaned',
              blank_count: 3
            }
          ]
        )
      end
    end

    context 'with multiple violations' do
      it 'parses violations for multiple objects' do
        output = <<~OUTPUT
          lib/example.rb:10: MyClass#process
          single:1
          lib/example.rb:20: MyClass#execute
          orphaned:2
        OUTPUT

        result = parser.call(output)

        expect(result).to eq(
          [
            {
              location: 'lib/example.rb',
              line: 10,
              object_name: 'MyClass#process',
              violation_type: 'single',
              blank_count: 1
            },
            {
              location: 'lib/example.rb',
              line: 20,
              object_name: 'MyClass#execute',
              violation_type: 'orphaned',
              blank_count: 2
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

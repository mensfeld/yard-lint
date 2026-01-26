# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::ExampleStyle::MessagesBuilder do
  describe '.call' do
    it 'builds message with all offense details' do
      offense = {
        object_name: 'User#initialize',
        example_name: 'Basic usage',
        cop_name: 'Style/StringLiterals',
        message: "Prefer single-quoted strings when you don't need interpolation"
      }

      message = described_class.call(offense)
      expect(message).to eq(
        "Object `User#initialize` has style offense in @example 'Basic usage': " \
        "Style/StringLiterals: Prefer single-quoted strings when you don't need interpolation"
      )
    end

    it 'handles different cop names' do
      offense = {
        object_name: 'User#save',
        example_name: 'Saving user',
        cop_name: 'Layout/SpaceInsideParens',
        message: 'Space inside parentheses detected'
      }

      message = described_class.call(offense)
      expect(message).to include('Layout/SpaceInsideParens')
      expect(message).to include('Space inside parentheses detected')
    end

    it 'handles example names with special characters' do
      offense = {
        object_name: 'User#find',
        example_name: 'Finding user (with options)',
        cop_name: 'Metrics/MethodLength',
        message: 'Method too long'
      }

      message = described_class.call(offense)
      expect(message).to include("'Finding user (with options)'")
    end
  end
end

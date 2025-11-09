# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::TypeSyntax::MessagesBuilder do
  describe '.call' do
    it 'formats type syntax violation message' do
      offense = {
        tag_name: 'param',
        type_string: 'Array<',
        error_message: "expecting name, got ''"
      }

      message = described_class.call(offense)

      expect(message).to eq("Invalid type syntax in @param tag: 'Array<' (expecting name, got '')")
    end

    it 'handles return tag violations' do
      offense = {
        tag_name: 'return',
        type_string: 'Hash{Symbol =>',
        error_message: "expecting name, got ''"
      }

      message = described_class.call(offense)

      expect(message).to eq(
        "Invalid type syntax in @return tag: 'Hash{Symbol =>' (expecting name, got '')"
      )
    end

    it 'handles option tag violations' do
      offense = {
        tag_name: 'option',
        type_string: 'Array<>',
        error_message: "expecting name, got '>'"
      }

      message = described_class.call(offense)

      expect(message).to eq(
        "Invalid type syntax in @option tag: 'Array<>' (expecting name, got '>')"
      )
    end
  end
end

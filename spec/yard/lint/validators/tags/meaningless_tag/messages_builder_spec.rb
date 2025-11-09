# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::MeaninglessTag::MessagesBuilder do
  describe '.call' do
    it 'formats message for @param on class' do
      offense = {
        object_type: 'class',
        tag_name: 'param',
        object_name: 'InvalidClass'
      }

      message = described_class.call(offense)

      expect(message).to eq(
        'The @param tag is meaningless on a class (InvalidClass). ' \
        'This tag only makes sense on methods.'
      )
    end

    it 'formats message for @option on module' do
      offense = {
        object_type: 'module',
        tag_name: 'option',
        object_name: 'InvalidModule'
      }

      message = described_class.call(offense)

      expect(message).to eq(
        'The @option tag is meaningless on a module (InvalidModule). ' \
        'This tag only makes sense on methods.'
      )
    end

    it 'formats message for @param on constant' do
      offense = {
        object_type: 'constant',
        tag_name: 'param',
        object_name: 'INVALID_CONSTANT'
      }

      message = described_class.call(offense)

      expect(message).to eq(
        'The @param tag is meaningless on a constant (INVALID_CONSTANT). ' \
        'This tag only makes sense on methods.'
      )
    end
  end
end

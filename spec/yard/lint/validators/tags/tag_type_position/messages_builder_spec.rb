# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::TagTypePosition::MessagesBuilder do
  describe '.call' do
    context 'when enforcing type_first but found type_after_name' do
      it 'formats message correctly for @param tag' do
        offense = {
          tag_name: 'param',
          param_name: 'user',
          type_info: 'String',
          detected_style: 'type_after_name'
        }

        message = described_class.call(offense)

        expect(message).to include('Type should appear before parameter name')
        expect(message).to include('@param')
        expect(message).to include('@param [String] user')
        expect(message).to include("instead of '@param user [String]'")
      end

      it 'formats message correctly for @option tag' do
        offense = {
          tag_name: 'option',
          param_name: 'opts',
          type_info: 'Hash',
          detected_style: 'type_after_name'
        }

        message = described_class.call(offense)

        expect(message).to include('Type should appear before parameter name')
        expect(message).to include('@option')
        expect(message).to include('@option [Hash] opts')
        expect(message).to include("instead of '@option opts [Hash]'")
      end
    end

    context 'when enforcing type_after_name but found type_first' do
      it 'formats message correctly for @param tag' do
        offense = {
          tag_name: 'param',
          param_name: 'name',
          type_info: 'String',
          detected_style: 'type_first'
        }

        message = described_class.call(offense)

        expect(message).to include('Type should appear after parameter name')
        expect(message).to include('@param')
        expect(message).to include('@param name [String]')
        expect(message).to include("instead of '@param [String] name'")
      end

      it 'formats message correctly for @option tag' do
        offense = {
          tag_name: 'option',
          param_name: 'config',
          type_info: 'Hash{Symbol => Object}',
          detected_style: 'type_first'
        }

        message = described_class.call(offense)

        expect(message).to include('Type should appear after parameter name')
        expect(message).to include('@option')
        expect(message).to include('@option config [Hash{Symbol => Object}]')
        expect(message).to include("instead of '@option [Hash{Symbol => Object}] config'")
      end
    end

    context 'with complex type annotations' do
      it 'handles nested types correctly' do
        offense = {
          tag_name: 'param',
          param_name: 'options',
          type_info: 'Hash{String => Array<Integer>}',
          detected_style: 'type_after_name'
        }

        message = described_class.call(offense)

        expect(message).to include('Hash{String => Array<Integer>}')
        expect(message).to include('@param [Hash{String => Array<Integer>}] options')
      end
    end
  end
end

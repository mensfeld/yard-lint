# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::TagGroupSeparator::MessagesBuilder do
  describe '.call' do
    context 'with single missing separator' do
      let(:offense) do
        {
          method_name: 'call',
          separators: 'param->return'
        }
      end

      it 'generates message for single transition' do
        message = described_class.call(offense)
        expect(message).to eq(
          'The `call` is missing a blank line between `param` and `return` tag groups.'
        )
      end
    end

    context 'with multiple missing separators' do
      let(:offense) do
        {
          method_name: 'process',
          separators: 'param->return,return->error'
        }
      end

      it 'generates message listing all transitions' do
        message = described_class.call(offense)
        expect(message).to eq(
          'The `process` is missing blank lines between tag groups: ' \
          '`param` -> `return`, `return` -> `error`.'
        )
      end
    end

    context 'with description to tag transition' do
      let(:offense) do
        {
          method_name: 'initialize',
          separators: 'description->param'
        }
      end

      it 'handles description group in message' do
        message = described_class.call(offense)
        expect(message).to eq(
          'The `initialize` is missing a blank line between `description` and `param` tag groups.'
        )
      end
    end
  end
end

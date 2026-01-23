# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Documentation::MissingReturn::MessagesBuilder do
  describe '.call' do
    it 'builds message for instance method' do
      offense = { element: 'Calculator#add' }
      message = described_class.call(offense)

      expect(message).to eq('Missing @return tag for `Calculator#add`')
    end

    it 'builds message for class method' do
      offense = { element: 'Calculator.new' }
      message = described_class.call(offense)

      expect(message).to eq('Missing @return tag for `Calculator.new`')
    end

    it 'builds message for namespaced class instance method' do
      offense = { element: 'Foo::Bar::Baz#method' }
      message = described_class.call(offense)

      expect(message).to eq('Missing @return tag for `Foo::Bar::Baz#method`')
    end

    it 'builds message for method with special characters' do
      offense = { element: 'Example#valid?' }
      message = described_class.call(offense)

      expect(message).to eq('Missing @return tag for `Example#valid?`')
    end

    it 'includes element name in backticks' do
      offense = { element: 'MyClass#my_method' }
      message = described_class.call(offense)

      expect(message).to include('`MyClass#my_method`')
    end

    it 'starts with "Missing @return tag for"' do
      offense = { element: 'AnyClass#any_method' }
      message = described_class.call(offense)

      expect(message).to start_with('Missing @return tag for')
    end
  end
end

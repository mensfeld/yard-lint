# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Documentation::UndocumentedBooleanMethods::Validator do
  let(:config) { Yard::Lint::Config.new }
  let(:selection) { ['lib/example.rb'] }
  let(:validator) { described_class.new(config, selection) }

  describe '#initialize' do
    it 'inherits from Base validator' do
      expect(validator).to be_a(Yard::Lint::Validators::Base)
    end

    it 'stores config and selection' do
      expect(validator.config).to eq(config)
      expect(validator.selection).to eq(selection)
    end
  end

  describe '.in_process?' do
    it 'returns true for in-process execution' do
      expect(described_class.in_process?).to be true
    end
  end
end

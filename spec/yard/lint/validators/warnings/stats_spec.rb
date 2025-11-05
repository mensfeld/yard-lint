# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Warnings::Stats do
  describe 'module structure' do
    it 'is defined as a module' do
      expect(described_class).to be_a(Module)
    end

    it 'has Config class' do
      expect(described_class.const_defined?(:Config)).to be true
    end

    it 'has Validator class' do
      expect(described_class.const_defined?(:Validator)).to be true
    end

    it 'has Result class' do
      expect(described_class.const_defined?(:Result)).to be true
    end

    it 'has warning type parsers' do
      expect(described_class.const_defined?(:UnknownTag)).to be true
      expect(described_class.const_defined?(:UnknownDirective)).to be true
      expect(described_class.const_defined?(:InvalidTagFormat)).to be true
    end
  end
end

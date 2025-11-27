# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::NonAsciiType::Validator do
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

  describe 'NON_ASCII_PATTERN' do
    let(:pattern) { described_class::NON_ASCII_PATTERN }

    it 'matches non-ASCII characters' do
      ellipsis = '…'
      arrow = '→'
      em_dash = '—'
      accented = 'é'

      expect(ellipsis).to match(pattern)
      expect(arrow).to match(pattern)
      expect(em_dash).to match(pattern)
      expect(accented).to match(pattern)
    end

    it 'does not match ASCII characters' do
      simple_type = 'String'
      generic_type = 'Array<Integer>'
      hash_type = 'Hash{Symbol => String}'

      expect(simple_type).not_to match(pattern)
      expect(generic_type).not_to match(pattern)
      expect(hash_type).not_to match(pattern)
    end
  end
end

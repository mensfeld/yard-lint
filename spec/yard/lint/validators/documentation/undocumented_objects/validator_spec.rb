# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Documentation::UndocumentedObjects::Validator do
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

  describe '#call' do
    it 'returns hash with stdout, stderr, exit_code' do
      result = validator.call
      expect(result).to have_key(:stdout)
      expect(result).to have_key(:stderr)
      expect(result).to have_key(:exit_code)
    end
  end
end

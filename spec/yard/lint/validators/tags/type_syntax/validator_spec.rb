# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::TypeSyntax::Validator do
  let(:config) { Yard::Lint::Config.new }
  let(:selection) { [] }
  let(:validator) { described_class.new(config, selection) }

  describe 'inheritance' do
    it 'inherits from Validators::Base' do
      expect(described_class.superclass).to eq(Yard::Lint::Validators::Base)
    end
  end

  describe '#call' do
    it 'returns a hash with command execution results' do
      result = validator.call
      expect(result).to be_a(Hash)
      expect(result).to have_key(:stdout)
      expect(result).to have_key(:stderr)
      expect(result).to have_key(:exit_code)
    end
  end
end

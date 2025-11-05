# frozen_string_literal: true

RSpec.describe Yard::Lint do
  describe 'VERSION' do
    it 'has a version number' do
      expect(Yard::Lint::VERSION).not_to be_nil
    end

    it 'version is a string' do
      expect(Yard::Lint::VERSION).to be_a(String)
    end

    it 'version follows semantic versioning format' do
      expect(Yard::Lint::VERSION).to match(/\A\d+\.\d+\.\d+/)
    end

    it 'version is frozen' do
      expect(Yard::Lint::VERSION).to be_frozen
    end
  end
end

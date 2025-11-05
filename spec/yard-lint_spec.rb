# frozen_string_literal: true

RSpec.describe 'yard-lint' do
  describe 'gem loading' do
    it 'loads without errors' do
      expect { require 'yard-lint' }.not_to raise_error
    end

    it 'defines Yard module' do
      expect(defined?(Yard)).to eq('constant')
    end

    it 'defines Yard::Lint module' do
      expect(defined?(Yard::Lint)).to eq('constant')
    end
  end

  describe 'Zeitwerk loader' do
    it 'auto-loads validators' do
      expect(defined?(Yard::Lint::Validators)).to eq('constant')
    end

    it 'auto-loads results' do
      expect(defined?(Yard::Lint::Results)).to eq('constant')
    end

    it 'auto-loads config' do
      expect(defined?(Yard::Lint::Config)).to eq('constant')
    end
  end

  describe 'manual requires' do
    it 'loads base config class' do
      expect(defined?(Yard::Lint::Validators::Config)).to eq('constant')
    end

    it 'loads main Yard::Lint module' do
      expect(Yard::Lint).to respond_to(:run)
    end
  end
end

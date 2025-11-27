# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::NonAsciiType do
  it 'is a module' do
    expect(described_class).to be_a(Module)
  end

  it 'is defined under Tags namespace' do
    expect(described_class.name).to eq('Yard::Lint::Validators::Tags::NonAsciiType')
  end
end

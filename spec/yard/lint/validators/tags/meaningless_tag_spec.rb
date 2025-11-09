# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::MeaninglessTag do
  it 'has all required components' do
    expect(defined?(described_class)).to be_truthy
    expect(defined?(described_class::Config)).to be_truthy
    expect(defined?(described_class::Parser)).to be_truthy
    expect(defined?(described_class::Validator)).to be_truthy
    expect(defined?(described_class::Result)).to be_truthy
    expect(defined?(described_class::MessagesBuilder)).to be_truthy
  end
end

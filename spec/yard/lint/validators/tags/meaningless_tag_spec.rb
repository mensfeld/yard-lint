# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::MeaninglessTag do
  it 'has all required components' do
    expect(defined?(Yard::Lint::Validators::Tags::MeaninglessTag)).to be_truthy
    expect(defined?(Yard::Lint::Validators::Tags::MeaninglessTag::Config)).to be_truthy
    expect(defined?(Yard::Lint::Validators::Tags::MeaninglessTag::Parser)).to be_truthy
    expect(defined?(Yard::Lint::Validators::Tags::MeaninglessTag::Validator)).to be_truthy
    expect(defined?(Yard::Lint::Validators::Tags::MeaninglessTag::Result)).to be_truthy
    expect(defined?(Yard::Lint::Validators::Tags::MeaninglessTag::MessagesBuilder)).to be_truthy
  end
end

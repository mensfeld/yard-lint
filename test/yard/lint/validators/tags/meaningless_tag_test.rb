# frozen_string_literal: true

describe 'Yard::Lint::Validators::Tags::MeaninglessTag' do
  it 'has all required components' do
  assert(defined?(Yard::Lint::Validators::Tags::MeaninglessTag))
  assert(defined?(Yard::Lint::Validators::Tags::MeaninglessTag::Config))
  assert(defined?(Yard::Lint::Validators::Tags::MeaninglessTag::Parser))
  assert(defined?(Yard::Lint::Validators::Tags::MeaninglessTag::Validator))
  assert(defined?(Yard::Lint::Validators::Tags::MeaninglessTag::Result))
  assert(defined?(Yard::Lint::Validators::Tags::MeaninglessTag::MessagesBuilder))
  end
end


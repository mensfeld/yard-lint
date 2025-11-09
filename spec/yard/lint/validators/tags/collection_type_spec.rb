# frozen_string_literal: true

RSpec.describe 'Tags/CollectionType Validator' do
  it 'has all required components' do
    expect(defined?(Yard::Lint::Validators::Tags::CollectionType::Validator)).to be_truthy
    expect(defined?(Yard::Lint::Validators::Tags::CollectionType::Parser)).to be_truthy
    expect(defined?(Yard::Lint::Validators::Tags::CollectionType::Result)).to be_truthy
    expect(defined?(Yard::Lint::Validators::Tags::CollectionType::Config)).to be_truthy
    expect(defined?(Yard::Lint::Validators::Tags::CollectionType::MessagesBuilder)).to be_truthy
  end
end

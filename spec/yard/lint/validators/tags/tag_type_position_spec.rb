# frozen_string_literal: true

RSpec.describe 'Tags/TagTypePosition Validator' do
  it 'has all required components' do
    expect(defined?(Yard::Lint::Validators::Tags::TagTypePosition::Validator)).to be_truthy
    expect(defined?(Yard::Lint::Validators::Tags::TagTypePosition::Parser)).to be_truthy
    expect(defined?(Yard::Lint::Validators::Tags::TagTypePosition::Result)).to be_truthy
    expect(defined?(Yard::Lint::Validators::Tags::TagTypePosition::Config)).to be_truthy
    expect(defined?(Yard::Lint::Validators::Tags::TagTypePosition::MessagesBuilder)).to be_truthy
  end
end

# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Validators::Tags::CollectionType' do
  it 'has all required components' do
  assert(defined?(Yard::Lint::Validators::Tags::CollectionType::Validator))
  assert(defined?(Yard::Lint::Validators::Tags::CollectionType::Parser))
  assert(defined?(Yard::Lint::Validators::Tags::CollectionType::Result))
  assert(defined?(Yard::Lint::Validators::Tags::CollectionType::Config))
  assert(defined?(Yard::Lint::Validators::Tags::CollectionType::MessagesBuilder))
  end
end


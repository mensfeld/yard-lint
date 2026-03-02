# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Validators::Tags::TagTypePosition' do
  it 'has all required components' do
  assert(defined?(Yard::Lint::Validators::Tags::TagTypePosition::Validator))
  assert(defined?(Yard::Lint::Validators::Tags::TagTypePosition::Parser))
  assert(defined?(Yard::Lint::Validators::Tags::TagTypePosition::Result))
  assert(defined?(Yard::Lint::Validators::Tags::TagTypePosition::Config))
  assert(defined?(Yard::Lint::Validators::Tags::TagTypePosition::MessagesBuilder))
  end
end


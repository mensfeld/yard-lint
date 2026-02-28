# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsTagTypePositionTest < Minitest::Test

  def test_has_all_required_components
  assert(defined?(Yard::Lint::Validators::Tags::TagTypePosition::Validator))
  assert(defined?(Yard::Lint::Validators::Tags::TagTypePosition::Parser))
  assert(defined?(Yard::Lint::Validators::Tags::TagTypePosition::Result))
  assert(defined?(Yard::Lint::Validators::Tags::TagTypePosition::Config))
  assert(defined?(Yard::Lint::Validators::Tags::TagTypePosition::MessagesBuilder))
  end
end


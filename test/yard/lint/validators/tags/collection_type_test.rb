# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsCollectionTypeTest < Minitest::Test

  def test_has_all_required_components
  assert(defined?(Yard::Lint::Validators::Tags::CollectionType::Validator))
  assert(defined?(Yard::Lint::Validators::Tags::CollectionType::Parser))
  assert(defined?(Yard::Lint::Validators::Tags::CollectionType::Result))
  assert(defined?(Yard::Lint::Validators::Tags::CollectionType::Config))
  assert(defined?(Yard::Lint::Validators::Tags::CollectionType::MessagesBuilder))
  end
end


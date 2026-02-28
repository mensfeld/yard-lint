# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsInformalNotationTest < Minitest::Test

  def test_has_all_required_components
  assert(defined?(Yard::Lint::Validators::Tags::InformalNotation))
  assert(defined?(Yard::Lint::Validators::Tags::InformalNotation::Config))
  assert(defined?(Yard::Lint::Validators::Tags::InformalNotation::Parser))
  assert(defined?(Yard::Lint::Validators::Tags::InformalNotation::Validator))
  assert(defined?(Yard::Lint::Validators::Tags::InformalNotation::Result))
  assert(defined?(Yard::Lint::Validators::Tags::InformalNotation::MessagesBuilder))
  end
end


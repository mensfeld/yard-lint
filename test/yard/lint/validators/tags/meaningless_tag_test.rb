# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsMeaninglessTagTest < Minitest::Test

  def test_has_all_required_components
  assert(defined?(Yard::Lint::Validators::Tags::MeaninglessTag))
  assert(defined?(Yard::Lint::Validators::Tags::MeaninglessTag::Config))
  assert(defined?(Yard::Lint::Validators::Tags::MeaninglessTag::Parser))
  assert(defined?(Yard::Lint::Validators::Tags::MeaninglessTag::Validator))
  assert(defined?(Yard::Lint::Validators::Tags::MeaninglessTag::Result))
  assert(defined?(Yard::Lint::Validators::Tags::MeaninglessTag::MessagesBuilder))
  end
end


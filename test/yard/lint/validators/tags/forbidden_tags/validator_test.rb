# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsForbiddenTagsValidatorTest < Minitest::Test
  attr_reader :config, :selection, :validator

  def setup
    @config = Yard::Lint::Config.new
    @selection = ['lib/example.rb']
    @validator = Yard::Lint::Validators::Tags::ForbiddenTags::Validator.new(config, selection)
  end

  def test_initialize_inherits_from_base_validator
    assert_kind_of(Yard::Lint::Validators::Base, validator)
  end

  def test_initialize_stores_config_and_selection
  end

  def test_in_process_returns_true_for_in_process_execution
    assert_equal(true, Yard::Lint::Validators::Tags::ForbiddenTags::Validator.in_process?)
  end
end


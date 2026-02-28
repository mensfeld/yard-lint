# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsWarningsInvalidTagFormatValidatorTest < Minitest::Test
  attr_reader :config, :selection, :validator

  def setup
    @config = Yard::Lint::Config.new
    @selection = ['lib/example.rb']
    @validator = Yard::Lint::Validators::Warnings::InvalidTagFormat::Validator.new(config, selection)
  end

  def test_initialize_inherits_from_base_validator
    assert_kind_of(Yard::Lint::Validators::Base, validator)
  end

  def test_initialize_stores_config_and_selection
  end
end


# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsWarningsDuplicatedParameterNameResultTest < Minitest::Test
  attr_reader :config, :parsed_data, :result

  def setup
    @config = Yard::Lint::Config.new
    @parsed_data = []
    @result = Yard::Lint::Validators::Warnings::DuplicatedParameterName::Result.new(parsed_data, config)
  end

  def test_initialize_inherits_from_base_result
    assert_kind_of(Yard::Lint::Results::Base, result)
  end

  def test_initialize_stores_config
    assert_equal(config, result.instance_variable_get(:@config))
  end

  def test_offenses_returns_an_array
    assert_kind_of(Array, result.offenses)
  end

  def test_offenses_returns_empty_array_for_empty_parsed_data
    assert_equal([], result.offenses)
  end
end

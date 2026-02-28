# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsNonAsciiTypeValidatorTest < Minitest::Test

  attr_reader :validator, :pattern

  def setup
    @config = Yard::Lint::Config.new
    @selection = ['lib/example.rb']
    @validator = Yard::Lint::Validators::Tags::NonAsciiType::Validator.new(@config, @selection)
    @pattern = Yard::Lint::Validators::Tags::NonAsciiType::Validator::NON_ASCII_PATTERN
  end

  def test_initialize_inherits_from_base_validator
    assert_kind_of(Yard::Lint::Validators::Base, validator)
  end

  def test_initialize_stores_config_and_selection
    assert_equal(@config, validator.config)
    assert_equal(@selection, validator.selection)
  end

  def test_in_process_returns_true_for_in_process_execution
    assert_equal(true, Yard::Lint::Validators::Tags::NonAsciiType::Validator.in_process?)
  end

  def test_non_ascii_pattern_matches_non_ascii_characters
    ellipsis = "\u2026"
    arrow = "\u2192"
    em_dash = "\u2014"
    accented = "\u00e9"

    assert_match(pattern, ellipsis)
    assert_match(pattern, arrow)
    assert_match(pattern, em_dash)
    assert_match(pattern, accented)
  end

  def test_non_ascii_pattern_does_not_match_ascii_characters
    simple_type = 'String'
    generic_type = 'Array<Integer>'
    hash_type = 'Hash{Symbol => String}'

    refute_match(pattern, simple_type)
    refute_match(pattern, generic_type)
    refute_match(pattern, hash_type)
  end
end

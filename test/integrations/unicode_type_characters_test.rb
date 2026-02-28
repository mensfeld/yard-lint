# frozen_string_literal: true

require 'test_helper'

class UnicodeCharactersInTypeSpecificationsTest < Minitest::Test
  attr_reader :config, :fixture_path

  def setup
    @fixture_path = File.expand_path('../fixtures/unicode_type_characters.rb', __dir__)
  end

  # -- When type specification contains Unicode characters (enabled) --

  def setup_non_ascii_enabled
    @config = test_config do |c|
      c.set_validator_config('Tags/NonAsciiType', 'Enabled', true)
    end
  end

  def test_when_type_specification_contains_unicode_characters_does_not_crash_with_encoding_compatibility_error
    setup_non_ascii_enabled

    # Issue #39: yard-lint crashes with "invalid byte sequence in UTF-8"
    # when encountering Unicode characters in type specifications
    # instead of handling them gracefully
    Yard::Lint.run(path: fixture_path, config: config)
  end

  def test_when_type_specification_contains_unicode_characters_continues_processing_and_returns_a_valid_result
    setup_non_ascii_enabled

    result = Yard::Lint.run(path: fixture_path, config: config)

    assert_respond_to(result, :offenses)
    assert_kind_of(Array, result.offenses)
  end

  def test_when_type_specification_contains_unicode_characters_reports_nonasciitype_offenses_for_each_method
    setup_non_ascii_enabled

    result = Yard::Lint.run(path: fixture_path, config: config)

    non_ascii_offenses = result.offenses.select { |o| o[:name] == 'NonAsciiType' }

    # Should detect the 3 methods with Unicode characters in type specs:
    # - unicode_ellipsis (...)
    # - unicode_arrow (->)
    # - unicode_em_dash (--)
    assert_equal(3, non_ascii_offenses.size)
  end

  def test_when_type_specification_contains_unicode_characters_includes_the_unicode_character_and_code_point_in_the_message
    setup_non_ascii_enabled

    result = Yard::Lint.run(path: fixture_path, config: config)

    non_ascii_offenses = result.offenses.select { |o| o[:name] == 'NonAsciiType' }

    non_ascii_offenses.each do |offense|
      assert_match(/U\+[0-9A-F]{4}/, offense[:message])
    end
  end

  def test_when_type_specification_contains_unicode_characters_does_not_report_offenses_for_valid_ascii_type_specifications
    setup_non_ascii_enabled

    result = Yard::Lint.run(path: fixture_path, config: config)

    non_ascii_offenses = result.offenses.select { |o| o[:name] == 'NonAsciiType' }

    valid_method_offenses = non_ascii_offenses.select do |o|
      o[:method_name]&.include?('valid_ascii_types')
    end

    assert_empty(valid_method_offenses)
  end

  def test_when_type_specification_contains_unicode_characters_detects_horizontal_ellipsis_u_2026
    setup_non_ascii_enabled

    result = Yard::Lint.run(path: fixture_path, config: config)

    ellipsis_offenses = result.offenses.select do |o|
      o[:name] == 'NonAsciiType' && o[:message]&.include?('U+2026')
    end

    assert_equal(1, ellipsis_offenses.size)
    assert_includes(ellipsis_offenses.first[:message], "'…'")
  end

  def test_when_type_specification_contains_unicode_characters_detects_right_arrow_u_2192
    setup_non_ascii_enabled

    result = Yard::Lint.run(path: fixture_path, config: config)

    arrow_offenses = result.offenses.select do |o|
      o[:name] == 'NonAsciiType' && o[:message]&.include?('U+2192')
    end

    assert_equal(1, arrow_offenses.size)
    assert_includes(arrow_offenses.first[:message], "'→'")
  end

  def test_when_type_specification_contains_unicode_characters_detects_em_dash_u_2014
    setup_non_ascii_enabled

    result = Yard::Lint.run(path: fixture_path, config: config)

    em_dash_offenses = result.offenses.select do |o|
      o[:name] == 'NonAsciiType' && o[:message]&.include?('U+2014')
    end

    assert_equal(1, em_dash_offenses.size)
    assert_includes(em_dash_offenses.first[:message], "'—'")
  end

  def test_when_type_specification_contains_unicode_characters_includes_helpful_guidance_in_the_error_message
    setup_non_ascii_enabled

    result = Yard::Lint.run(path: fixture_path, config: config)

    non_ascii_offenses = result.offenses.select { |o| o[:name] == 'NonAsciiType' }

    non_ascii_offenses.each do |offense|
      assert_includes(offense[:message], 'Ruby type names must use ASCII characters only')
    end
  end

  def test_when_type_specification_contains_unicode_characters_sets_severity_to_warning
    setup_non_ascii_enabled

    result = Yard::Lint.run(path: fixture_path, config: config)

    non_ascii_offenses = result.offenses.select { |o| o[:name] == 'NonAsciiType' }

    non_ascii_offenses.each do |offense|
      assert_equal('warning', offense[:severity])
    end
  end

  def test_when_type_specification_contains_unicode_characters_provides_correct_file_location
    setup_non_ascii_enabled

    result = Yard::Lint.run(path: fixture_path, config: config)

    non_ascii_offenses = result.offenses.select { |o| o[:name] == 'NonAsciiType' }

    non_ascii_offenses.each do |offense|
      assert_includes(offense[:location], 'unicode_type_characters.rb')
    end
  end

  # -- When validator is disabled --

  def setup_non_ascii_disabled
    @config = test_config do |c|
      c.set_validator_config('Tags/NonAsciiType', 'Enabled', false)
    end
  end

  def test_when_validator_is_disabled_does_not_report_nonasciitype_offenses
    setup_non_ascii_disabled

    result = Yard::Lint.run(path: fixture_path, config: config)

    non_ascii_offenses = result.offenses.select { |o| o[:name] == 'NonAsciiType' }
    assert_empty(non_ascii_offenses)
  end

  def test_when_validator_is_disabled_still_does_not_crash_with_encoding_errors
    setup_non_ascii_disabled

    Yard::Lint.run(path: fixture_path, config: config)
  end

  # -- Interaction with TypeSyntax validator --

  def setup_non_ascii_with_type_syntax
    @config = test_config do |c|
      c.set_validator_config('Tags/NonAsciiType', 'Enabled', true)
      c.set_validator_config('Tags/TypeSyntax', 'Enabled', true)
    end
  end

  def test_interaction_with_typesyntax_validator_both_validators_can_run_together_without_crashing
    setup_non_ascii_with_type_syntax

    Yard::Lint.run(path: fixture_path, config: config)
  end

  def test_interaction_with_typesyntax_validator_nonasciitype_reports_its_offenses_independently
    setup_non_ascii_with_type_syntax

    result = Yard::Lint.run(path: fixture_path, config: config)

    non_ascii_offenses = result.offenses.select { |o| o[:name] == 'NonAsciiType' }
    assert_equal(3, non_ascii_offenses.size)
  end

  # -- With custom ValidatedTags configuration --

  def test_with_custom_validatedtags_configuration_only_validates_configured_tags
    @config = test_config do |c|
      c.set_validator_config('Tags/NonAsciiType', 'Enabled', true)
      c.set_validator_config('Tags/NonAsciiType', 'ValidatedTags', %w[return])
    end

    result = Yard::Lint.run(path: fixture_path, config: config)

    non_ascii_offenses = result.offenses.select { |o| o[:name] == 'NonAsciiType' }

    # Only @return tags should be checked, so only unicode_arrow should be detected
    # (it's the only one with Unicode in the @return tag in the fixture)
    assert_operator(non_ascii_offenses.size, :<=, 1)
  end
end

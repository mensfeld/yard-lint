# frozen_string_literal: true

require 'test_helper'

class TypeSyntaxValidationIntegrationTest < Minitest::Test
  attr_reader :config, :fixture_path

  def setup
    @fixture_path = File.expand_path('../fixtures/type_syntax_examples.rb', __dir__)
    @config = test_config do |c|
      c.send(:set_validator_config, 'Tags/TypeSyntax', 'Enabled', true)
    end
  end

  def test_detecting_type_syntax_errors_detects_unclosed_bracket_in_param_tag
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find do |o|
      o[:name] == 'InvalidTypeSyntax' && o[:message].include?('Array<')
    end

    refute_nil(offense)
    assert_equal(fixture_path, offense[:location])
    assert_equal('warning', offense[:severity])
    assert_includes(offense[:message], 'Invalid type syntax')
    assert_includes(offense[:message], '@param')
  end

  def test_detecting_type_syntax_errors_detects_empty_generic_in_return_tag
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find do |o|
      o[:name] == 'InvalidTypeSyntax' && o[:message].include?('Array<>')
    end

    refute_nil(offense)
    assert_includes(offense[:message], '@return')
  end

  def test_detecting_type_syntax_errors_detects_unclosed_hash_syntax
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find do |o|
      o[:name] == 'InvalidTypeSyntax' && o[:message].include?('Hash{Symbol =>')
    end

    refute_nil(offense)
    assert_includes(offense[:message], 'Invalid type syntax')
  end

  def test_detecting_type_syntax_errors_detects_malformed_hash_syntax
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find do |o|
      o[:name] == 'InvalidTypeSyntax' && o[:message].include?('Hash{Symbol]')
    end

    refute_nil(offense)
  end

  def test_detecting_type_syntax_errors_does_not_flag_valid_type_syntax
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    # Should not flag valid_types method
    valid_offense = result.offenses.find do |o|
      o[:name] == 'InvalidTypeSyntax' && o[:message].include?('valid_types')
    end

    assert_nil(valid_offense)
  end

  def test_detecting_type_syntax_errors_does_not_flag_multiple_types_union_syntax
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    # Should not flag multiple_types method
    union_offense = result.offenses.find do |o|
      o[:name] == 'InvalidTypeSyntax' && o[:message].include?('String, Integer')
    end

    assert_nil(union_offense)
  end

  def test_detecting_type_syntax_errors_does_not_flag_nested_generics
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    # Should not flag nested_generics method
    nested_offense = result.offenses.find do |o|
      o[:name] == 'InvalidTypeSyntax' && o[:message].include?('Array<Array<Integer>>')
    end

    assert_nil(nested_offense)
  end

  def test_validator_configuration_when_typesyntax_validator_is_disabled_does_not_report_type_syntax_violations
    disabled_config = test_config do |c|
      c.send(:set_validator_config, 'Tags/TypeSyntax', 'Enabled', false)
    end

    result = Yard::Lint.run(path: fixture_path, config: disabled_config, progress: false)

    type_syntax_offenses = result.offenses.select { |o| o[:name] == 'InvalidTypeSyntax' }

    assert_empty(type_syntax_offenses)
  end

  def test_validator_configuration_when_validatedtags_is_customized_only_validates_specified_tags
    custom_config = test_config do |c|
      c.send(:set_validator_config, 'Tags/TypeSyntax', 'Enabled', true)
      c.send(:set_validator_config, 'Tags/TypeSyntax', 'ValidatedTags', ['return'])
    end

    result = Yard::Lint.run(path: fixture_path, config: custom_config, progress: false)

    type_syntax_offenses = result.offenses.select { |o| o[:name] == 'InvalidTypeSyntax' }

    # Should find @return violations but not @param violations
    return_offenses = type_syntax_offenses.select { |o| o[:message].include?('@return') }
    param_offenses = type_syntax_offenses.select { |o| o[:message].include?('@param') }

    refute_empty(return_offenses)
    assert_empty(param_offenses)
  end

  def test_offense_details_includes_file_path_in_location
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find { |o| o[:name] == 'InvalidTypeSyntax' }

    assert_equal(fixture_path, offense[:location])
    refute_empty(offense[:location])
  end

  def test_offense_details_includes_line_number
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find { |o| o[:name] == 'InvalidTypeSyntax' }

    assert_operator(offense[:location_line], :>, 0)
  end

  def test_offense_details_includes_descriptive_message_with_error_details
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find { |o| o[:name] == 'InvalidTypeSyntax' }

    assert_includes(offense[:message], 'Invalid type syntax')
    assert_match(/@(param|return|option)/, offense[:message])
  end
end

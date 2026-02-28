# frozen_string_literal: true

require 'test_helper'

class YardLintConfigValidatorTest < Minitest::Test
  def test_validate_with_valid_configuration_does_not_raise_error_for_valid_config
    config = {
      'AllValidators' => {
        'Exclude' => ['vendor/**/*'],
        'FailOnSeverity' => 'error'
      },
      'Documentation/UndocumentedObjects' => {
        'Enabled' => true,
        'Severity' => 'warning'
      }
    }

    Yard::Lint::ConfigValidator.validate!(config)
  end

  def test_validate_with_valid_configuration_does_not_raise_error_for_empty_config
    Yard::Lint::ConfigValidator.validate!({})
  end

  def test_validate_with_invalid_validator_names_raises_error_for_non_existent_validator
    config = {
      'UndocumentedMethod' => {
        'Enabled' => true
      }
    }

    error = assert_raises(Yard::Lint::Errors::InvalidConfigError) do
      Yard::Lint::ConfigValidator.validate!(config)
    end
    assert_match(/Unknown validator: 'UndocumentedMethod'/, error.message)
  end

  def test_validate_with_invalid_validator_names_raises_error_for_multiple_non_existent_validators
    config = {
      'UndocumentedMethod' => { 'Enabled' => true },
      'UndocumentedClass' => { 'Enabled' => true }
    }

    error = assert_raises(Yard::Lint::Errors::InvalidConfigError) do
      Yard::Lint::ConfigValidator.validate!(config)
    end
    assert_includes(error.message, "Unknown validator: 'UndocumentedMethod'")
    assert_includes(error.message, "Unknown validator: 'UndocumentedClass'")
  end

  def test_validate_with_invalid_validator_names_suggests_similar_validator_name
    config = {
      'Documentation/UndocumentedObject' => { 'Enabled' => true }
    }

    error = assert_raises(Yard::Lint::Errors::InvalidConfigError) do
      Yard::Lint::ConfigValidator.validate!(config)
    end
    assert_match(/Did you mean: Documentation\/UndocumentedObjects\?/, error.message)
  end

  def test_validate_with_invalid_severity_values_raises_error_for_typo_in_severity
    config = {
      'Documentation/UndocumentedObjects' => {
        'Enabled' => true,
        'Severity' => 'erro'
      }
    }

    error = assert_raises(Yard::Lint::Errors::InvalidConfigError) do
      Yard::Lint::ConfigValidator.validate!(config)
    end
    assert_includes(error.message, "Invalid Severity for Documentation/UndocumentedObjects: 'erro'")
    assert_includes(error.message, 'Valid values: error, warning, convention, never')
    assert_includes(error.message, 'Did you mean: error?')
  end

  def test_validate_with_invalid_severity_values_raises_error_for_invalid_global_failonseverity
    config = {
      'AllValidators' => {
        'FailOnSeverity' => 'critical'
      }
    }

    error = assert_raises(Yard::Lint::Errors::InvalidConfigError) do
      Yard::Lint::ConfigValidator.validate!(config)
    end
    assert_includes(error.message, "Invalid FailOnSeverity: 'critical'")
    assert_includes(error.message, 'Valid values: error, warning, convention, never')
  end

  def test_validate_with_invalid_enabled_values_raises_error_for_non_boolean_enabled_value
    config = {
      'Documentation/UndocumentedObjects' => {
        'Enabled' => 'yes'
      }
    }

    error = assert_raises(Yard::Lint::Errors::InvalidConfigError) do
      Yard::Lint::ConfigValidator.validate!(config)
    end
    assert_includes(error.message, "Invalid Enabled value for Documentation/UndocumentedObjects: 'yes'")
    assert_includes(error.message, 'Must be true or false')
  end

  def test_validate_with_invalid_global_settings_allows_unknown_allvalidators_keys_for_user_flexibility
    config = {
      'AllValidators' => {
        'UnknownSetting' => 'value',
        'Severity' => 'warning'
      }
    }

    # Unknown keys in AllValidators are allowed
    Yard::Lint::ConfigValidator.validate!(config)
  end

  def test_validate_with_invalid_global_settings_raises_error_for_invalid_mincoverage_value
    config = {
      'AllValidators' => {
        'MinCoverage' => 150
      }
    }

    error = assert_raises(Yard::Lint::Errors::InvalidConfigError) do
      Yard::Lint::ConfigValidator.validate!(config)
    end
    assert_includes(error.message, "Invalid MinCoverage: '150'")
    assert_includes(error.message, 'Must be a number between 0 and 100')
  end

  def test_validate_with_invalid_global_settings_raises_error_for_non_numeric_mincoverage
    config = {
      'AllValidators' => {
        'MinCoverage' => 'high'
      }
    }

    error = assert_raises(Yard::Lint::Errors::InvalidConfigError) do
      Yard::Lint::ConfigValidator.validate!(config)
    end
    assert_match(/Invalid MinCoverage/, error.message)
  end

  def test_validate_with_invalid_global_settings_raises_error_for_non_array_exclude
    config = {
      'AllValidators' => {
        'Exclude' => 'vendor/**/*'
      }
    }

    error = assert_raises(Yard::Lint::Errors::InvalidConfigError) do
      Yard::Lint::ConfigValidator.validate!(config)
    end
    assert_includes(error.message, 'Invalid Exclude in AllValidators: must be an array')
  end

  def test_validate_with_invalid_validator_specific_settings_raises_error_for_non_array_exclude_in_validator_config
    config = {
      'Documentation/UndocumentedObjects' => {
        'Exclude' => 'vendor/**/*'
      }
    }

    error = assert_raises(Yard::Lint::Errors::InvalidConfigError) do
      Yard::Lint::ConfigValidator.validate!(config)
    end
    assert_includes(error.message, 'Invalid Exclude for Documentation/UndocumentedObjects: must be an array')
  end

  def test_validate_with_invalid_validator_specific_settings_raises_error_for_unknown_validator_specific_key
    config = {
      'Tags/Order' => {
        'UnknownKey' => 'value'
      }
    }

    error = assert_raises(Yard::Lint::Errors::InvalidConfigError) do
      Yard::Lint::ConfigValidator.validate!(config)
    end
    assert_includes(error.message, "Unknown configuration key for Tags/Order: 'UnknownKey'")
    assert_includes(error.message, 'Valid keys:')
  end

  def test_validate_with_multiple_errors_reports_all_errors_at_once
    config = {
      'UndocumentedMethod' => { 'Enabled' => true },
      'Documentation/UndocumentedObjects' => {
        'Severity' => 'erro',
        'Enabled' => 'yes'
      }
    }

    error = assert_raises(Yard::Lint::Errors::InvalidConfigError) do
      Yard::Lint::ConfigValidator.validate!(config)
    end
    assert_includes(error.message, "Unknown validator: 'UndocumentedMethod'")
    assert_includes(error.message, 'Invalid Severity')
    assert_includes(error.message, 'Invalid Enabled value')
  end

  def test_validate_with_special_keys_allows_inherit_from
    config = {
      'inherit_from' => '.base-config.yml'
    }

    Yard::Lint::ConfigValidator.validate!(config)
  end

  def test_validate_with_special_keys_allows_inherit_gem
    config = {
      'inherit_gem' => {
        'rubocop-rspec' => '.rubocop.yml'
      }
    }

    Yard::Lint::ConfigValidator.validate!(config)
  end

  def test_validate_with_metadata_keys_allows_description_in_validator_config
    config = {
      'Documentation/UndocumentedObjects' => {
        'Description' => 'Custom description',
        'Enabled' => true
      }
    }

    Yard::Lint::ConfigValidator.validate!(config)
  end

  def test_validate_with_type_validation_raises_error_when_allvalidators_is_not_a_hash
    config = {
      'AllValidators' => true
    }

    error = assert_raises(Yard::Lint::Errors::InvalidConfigError) do
      Yard::Lint::ConfigValidator.validate!(config)
    end
    assert_includes(error.message, 'Invalid AllValidators: must be a Hash, got TrueClass')
  end

  def test_validate_with_type_validation_raises_error_when_validator_config_is_not_a_hash
    config = {
      'Tags/Order' => true
    }

    error = assert_raises(Yard::Lint::Errors::InvalidConfigError) do
      Yard::Lint::ConfigValidator.validate!(config)
    end
    assert_includes(error.message, "Invalid configuration for validator 'Tags/Order': expected a Hash, got TrueClass")
  end

  def test_validate_with_type_validation_raises_error_when_per_validator_yardoptions_is_not_an_array
    config = {
      'Documentation/UndocumentedObjects' => {
        'YardOptions' => '--private'
      }
    }

    error = assert_raises(Yard::Lint::Errors::InvalidConfigError) do
      Yard::Lint::ConfigValidator.validate!(config)
    end
    assert_includes(error.message, 'Invalid YardOptions for Documentation/UndocumentedObjects: must be an array')
  end
end

# frozen_string_literal: true

require 'test_helper'


describe 'Yard::Lint::ConfigValidator' do
  it 'validate with valid configuration does not raise error for valid config' do
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

  it 'validate with valid configuration does not raise error for empty config' do
    Yard::Lint::ConfigValidator.validate!({})
  end

  it 'validate with invalid validator names raises error for non existent validator' do
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

  it 'validate with invalid validator names raises error for multiple non existent validators' do
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

  it 'validate with invalid validator names suggests similar validator name' do
    config = {
      'Documentation/UndocumentedObject' => { 'Enabled' => true }
    }

    error = assert_raises(Yard::Lint::Errors::InvalidConfigError) do
      Yard::Lint::ConfigValidator.validate!(config)
    end
    assert_match(/Did you mean: Documentation\/UndocumentedObjects\?/, error.message)
  end

  it 'validate with invalid severity values raises error for typo in severity' do
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

  it 'validate with invalid severity values raises error for invalid global failonseverity' do
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

  it 'validate with invalid enabled values raises error for non boolean enabled value' do
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

  it 'validate with invalid global settings allows unknown allvalidators keys for user flexibility' do
    config = {
      'AllValidators' => {
        'UnknownSetting' => 'value',
        'Severity' => 'warning'
      }
    }

    # Unknown keys in AllValidators are allowed
    Yard::Lint::ConfigValidator.validate!(config)
  end

  it 'validate with invalid global settings raises error for invalid mincoverage value' do
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

  it 'validate with invalid global settings raises error for non numeric mincoverage' do
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

  it 'validate with invalid global settings raises error for non array exclude' do
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

  it 'validate with invalid validator specific settings raises error for non array exclude in validator config' do
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

  it 'validate with invalid validator specific settings raises error for unknown validator specific key' do
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

  it 'validate with multiple errors reports all errors at once' do
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

  it 'validate with special keys allows inherit from' do
    config = {
      'inherit_from' => '.base-config.yml'
    }

    Yard::Lint::ConfigValidator.validate!(config)
  end

  it 'validate with special keys allows inherit gem' do
    config = {
      'inherit_gem' => {
        'rubocop-rspec' => '.rubocop.yml'
      }
    }

    Yard::Lint::ConfigValidator.validate!(config)
  end

  it 'validate with metadata keys allows description in validator config' do
    config = {
      'Documentation/UndocumentedObjects' => {
        'Description' => 'Custom description',
        'Enabled' => true
      }
    }

    Yard::Lint::ConfigValidator.validate!(config)
  end

  it 'validate with type validation raises error when allvalidators is not a hash' do
    config = {
      'AllValidators' => true
    }

    error = assert_raises(Yard::Lint::Errors::InvalidConfigError) do
      Yard::Lint::ConfigValidator.validate!(config)
    end
    assert_includes(error.message, 'Invalid AllValidators: must be a Hash, got TrueClass')
  end

  it 'validate with type validation raises error when validator config is not a hash' do
    config = {
      'Tags/Order' => true
    }

    error = assert_raises(Yard::Lint::Errors::InvalidConfigError) do
      Yard::Lint::ConfigValidator.validate!(config)
    end
    assert_includes(error.message, "Invalid configuration for validator 'Tags/Order': expected a Hash, got TrueClass")
  end

  it 'validate with type validation raises error when per validator yardoptions is not an array' do
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

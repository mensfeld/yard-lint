# frozen_string_literal: true

RSpec.describe Yard::Lint::ConfigValidator do
  describe '.validate!' do
    context 'with valid configuration' do
      it 'does not raise error for valid config' do
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

        expect { described_class.validate!(config) }.not_to raise_error
      end

      it 'does not raise error for empty config' do
        expect { described_class.validate!({}) }.not_to raise_error
      end
    end

    context 'with invalid validator names' do
      it 'raises error for non-existent validator' do
        config = {
          'UndocumentedMethod' => {
            'Enabled' => true
          }
        }

        expect { described_class.validate!(config) }
          .to raise_error(Yard::Lint::Errors::InvalidConfigError, /Unknown validator: 'UndocumentedMethod'/)
      end

      it 'raises error for multiple non-existent validators' do
        config = {
          'UndocumentedMethod' => { 'Enabled' => true },
          'UndocumentedClass' => { 'Enabled' => true }
        }

        expect { described_class.validate!(config) }
          .to raise_error(Yard::Lint::Errors::InvalidConfigError) do |error|
          expect(error.message).to include("Unknown validator: 'UndocumentedMethod'")
          expect(error.message).to include("Unknown validator: 'UndocumentedClass'")
        end
      end

      it 'suggests similar validator name' do
        config = {
          'Documentation/UndocumentedObject' => { 'Enabled' => true }
        }

        expect { described_class.validate!(config) }
          .to raise_error(Yard::Lint::Errors::InvalidConfigError, /Did you mean: Documentation\/UndocumentedObjects\?/)
      end
    end

    context 'with invalid severity values' do
      it 'raises error for typo in severity' do
        config = {
          'Documentation/UndocumentedObjects' => {
            'Enabled' => true,
            'Severity' => 'erro'
          }
        }

        expect { described_class.validate!(config) }
          .to raise_error(Yard::Lint::Errors::InvalidConfigError) do |error|
          expect(error.message).to include("Invalid Severity for Documentation/UndocumentedObjects: 'erro'")
          expect(error.message).to include('Valid values: error, warning, convention, never')
          expect(error.message).to include('Did you mean: error?')
        end
      end

      it 'raises error for invalid global FailOnSeverity' do
        config = {
          'AllValidators' => {
            'FailOnSeverity' => 'critical'
          }
        }

        expect { described_class.validate!(config) }
          .to raise_error(Yard::Lint::Errors::InvalidConfigError) do |error|
          expect(error.message).to include("Invalid FailOnSeverity: 'critical'")
          expect(error.message).to include('Valid values: error, warning, convention, never')
        end
      end
    end

    context 'with invalid enabled values' do
      it 'raises error for non-boolean Enabled value' do
        config = {
          'Documentation/UndocumentedObjects' => {
            'Enabled' => 'yes'
          }
        }

        expect { described_class.validate!(config) }
          .to raise_error(Yard::Lint::Errors::InvalidConfigError) do |error|
          expect(error.message).to include("Invalid Enabled value for Documentation/UndocumentedObjects: 'yes'")
          expect(error.message).to include('Must be true or false')
        end
      end
    end

    context 'with invalid global settings' do
      it 'allows unknown AllValidators keys (for user flexibility)' do
        config = {
          'AllValidators' => {
            'UnknownSetting' => 'value',
            'Severity' => 'warning'
          }
        }

        # Unknown keys in AllValidators are allowed
        expect { described_class.validate!(config) }.not_to raise_error
      end

      it 'raises error for invalid MinCoverage value' do
        config = {
          'AllValidators' => {
            'MinCoverage' => 150
          }
        }

        expect { described_class.validate!(config) }
          .to raise_error(Yard::Lint::Errors::InvalidConfigError) do |error|
          expect(error.message).to include("Invalid MinCoverage: '150'")
          expect(error.message).to include('Must be a number between 0 and 100')
        end
      end

      it 'raises error for non-numeric MinCoverage' do
        config = {
          'AllValidators' => {
            'MinCoverage' => 'high'
          }
        }

        expect { described_class.validate!(config) }
          .to raise_error(Yard::Lint::Errors::InvalidConfigError, /Invalid MinCoverage/)
      end

      it 'raises error for non-array Exclude' do
        config = {
          'AllValidators' => {
            'Exclude' => 'vendor/**/*'
          }
        }

        expect { described_class.validate!(config) }
          .to raise_error(Yard::Lint::Errors::InvalidConfigError) do |error|
          expect(error.message).to include('Invalid Exclude in AllValidators: must be an array')
        end
      end
    end

    context 'with invalid validator-specific settings' do
      it 'raises error for non-array Exclude in validator config' do
        config = {
          'Documentation/UndocumentedObjects' => {
            'Exclude' => 'vendor/**/*'
          }
        }

        expect { described_class.validate!(config) }
          .to raise_error(Yard::Lint::Errors::InvalidConfigError) do |error|
          expect(error.message).to include('Invalid Exclude for Documentation/UndocumentedObjects: must be an array')
        end
      end

      it 'raises error for unknown validator-specific key' do
        config = {
          'Tags/Order' => {
            'UnknownKey' => 'value'
          }
        }

        expect { described_class.validate!(config) }
          .to raise_error(Yard::Lint::Errors::InvalidConfigError) do |error|
          expect(error.message).to include("Unknown configuration key for Tags/Order: 'UnknownKey'")
          expect(error.message).to include('Valid keys:')
        end
      end
    end

    context 'with multiple errors' do
      it 'reports all errors at once' do
        config = {
          'UndocumentedMethod' => { 'Enabled' => true },
          'Documentation/UndocumentedObjects' => {
            'Severity' => 'erro',
            'Enabled' => 'yes'
          }
        }

        expect { described_class.validate!(config) }
          .to raise_error(Yard::Lint::Errors::InvalidConfigError) do |error|
          expect(error.message).to include("Unknown validator: 'UndocumentedMethod'")
          expect(error.message).to include("Invalid Severity")
          expect(error.message).to include("Invalid Enabled value")
        end
      end
    end

    context 'with special keys' do
      it 'allows inherit_from' do
        config = {
          'inherit_from' => '.base-config.yml'
        }

        expect { described_class.validate!(config) }.not_to raise_error
      end

      it 'allows inherit_gem' do
        config = {
          'inherit_gem' => {
            'rubocop-rspec' => '.rubocop.yml'
          }
        }

        expect { described_class.validate!(config) }.not_to raise_error
      end
    end

    context 'with metadata keys' do
      it 'allows Description in validator config' do
        config = {
          'Documentation/UndocumentedObjects' => {
            'Description' => 'Custom description',
            'Enabled' => true
          }
        }

        expect { described_class.validate!(config) }.not_to raise_error
      end
    end

    context 'with type validation for config structures' do
      it 'raises error when AllValidators is not a Hash' do
        config = {
          'AllValidators' => true
        }

        expect { described_class.validate!(config) }
          .to raise_error(Yard::Lint::Errors::InvalidConfigError) do |error|
          expect(error.message).to include('Invalid AllValidators: must be a Hash, got TrueClass')
        end
      end

      it 'raises error when validator config is not a Hash' do
        config = {
          'Tags/Order' => true
        }

        expect { described_class.validate!(config) }
          .to raise_error(Yard::Lint::Errors::InvalidConfigError) do |error|
          expect(error.message).to include("Invalid configuration for validator 'Tags/Order': expected a Hash, got TrueClass")
        end
      end

      it 'raises error when per-validator YardOptions is not an array' do
        config = {
          'Documentation/UndocumentedObjects' => {
            'YardOptions' => '--private'
          }
        }

        expect { described_class.validate!(config) }
          .to raise_error(Yard::Lint::Errors::InvalidConfigError) do |error|
          expect(error.message).to include('Invalid YardOptions for Documentation/UndocumentedObjects: must be an array')
        end
      end
    end
  end
end

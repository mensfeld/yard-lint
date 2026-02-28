# frozen_string_literal: true

require 'tmpdir'
require 'open3'
require 'test_helper'

class InvalidConfigurationIntegrationTest < Minitest::Test
  def run_in_tmpdir
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.write('test.rb', <<~RUBY)
          class Foo
            def bar
            end
          end
        RUBY
        yield
      end
    end
  end

  def test_with_non_hash_validator_config_fails_with_clear_error_message
    run_in_tmpdir do
      bin_path = File.expand_path('../../bin/yard-lint', __dir__)
      File.write('.yard-lint.yml', <<~YAML)
        Tags/Order: true
      YAML

      output, status = Open3.capture2e(bin_path, 'test.rb')

      assert_equal(1, status.exitstatus)
      assert_includes(output, 'Configuration Error')
      assert_includes(output, "Invalid configuration for validator 'Tags/Order'")
      assert_includes(output, 'expected a Hash, got TrueClass')
    end
  end

  def test_with_non_hash_allvalidators_fails_with_clear_error_message
    run_in_tmpdir do
      bin_path = File.expand_path('../../bin/yard-lint', __dir__)
      File.write('.yard-lint.yml', <<~YAML)
        AllValidators: true
      YAML

      output, status = Open3.capture2e(bin_path, 'test.rb')

      assert_equal(1, status.exitstatus)
      assert_includes(output, 'Configuration Error')
      assert_includes(output, 'Invalid AllValidators: must be a Hash')
    end
  end

  def test_with_invalid_per_validator_yardoptions_type_fails_with_clear_error_message
    run_in_tmpdir do
      bin_path = File.expand_path('../../bin/yard-lint', __dir__)
      File.write('.yard-lint.yml', <<~YAML)
        Documentation/UndocumentedObjects:
          YardOptions: --private
      YAML

      output, status = Open3.capture2e(bin_path, 'test.rb')

      assert_equal(1, status.exitstatus)
      assert_includes(output, 'Configuration Error')
      assert_includes(output, 'Invalid YardOptions for Documentation/UndocumentedObjects')
      assert_includes(output, 'must be an array')
    end
  end

  def test_with_invalid_severity_typo_fails_with_did_you_mean_suggestion
    run_in_tmpdir do
      bin_path = File.expand_path('../../bin/yard-lint', __dir__)
      File.write('.yard-lint.yml', <<~YAML)
        Documentation/UndocumentedObjects:
          Severity: erro
      YAML

      output, status = Open3.capture2e(bin_path, 'test.rb')

      assert_equal(1, status.exitstatus)
      assert_includes(output, 'Configuration Error')
      assert_includes(output, "Invalid Severity for Documentation/UndocumentedObjects: 'erro'")
      assert_includes(output, 'Did you mean: error?')
    end
  end

  def test_with_unknown_validator_name_fails_with_did_you_mean_suggestion
    run_in_tmpdir do
      bin_path = File.expand_path('../../bin/yard-lint', __dir__)
      File.write('.yard-lint.yml', <<~YAML)
        UndocumentedMethod:
          Enabled: true
      YAML

      output, status = Open3.capture2e(bin_path, 'test.rb')

      assert_equal(1, status.exitstatus)
      assert_includes(output, 'Configuration Error')
      assert_includes(output, "Unknown validator: 'UndocumentedMethod'")
    end
  end

  def test_with_invalid_enabled_boolean_fails_with_clear_error_message
    run_in_tmpdir do
      bin_path = File.expand_path('../../bin/yard-lint', __dir__)
      File.write('.yard-lint.yml', <<~YAML)
        Documentation/UndocumentedObjects:
          Enabled: "enabled"
      YAML

      output, status = Open3.capture2e(bin_path, 'test.rb')

      assert_equal(1, status.exitstatus)
      assert_includes(output, 'Configuration Error')
      assert_includes(output, "Invalid Enabled value for Documentation/UndocumentedObjects: 'enabled'")
      assert_includes(output, 'Must be true or false')
    end
  end

  def test_with_valid_configuration_runs_successfully
    run_in_tmpdir do
      bin_path = File.expand_path('../../bin/yard-lint', __dir__)
      File.write('.yard-lint.yml', <<~YAML)
        AllValidators:
          Exclude:
            - spec/**/*
        Documentation/UndocumentedObjects:
          Enabled: false
      YAML

      output, status = Open3.capture2e(bin_path, 'test.rb')

      assert_equal(0, status.exitstatus)
      refute_includes(output, 'Configuration Error')
    end
  end

  def test_with_auto_gen_config_and_invalid_config_fails_with_clear_error_message
    run_in_tmpdir do
      bin_path = File.expand_path('../../bin/yard-lint', __dir__)
      File.write('.yard-lint.yml', <<~YAML)
        Tags/Order: invalid
      YAML

      output, status = Open3.capture2e(bin_path, '--auto-gen-config', 'test.rb')

      assert_equal(1, status.exitstatus)
      assert_includes(output, 'Configuration Error')
      assert_includes(output, "Invalid configuration for validator 'Tags/Order'")
    end
  end
end

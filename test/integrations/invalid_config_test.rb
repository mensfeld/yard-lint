# frozen_string_literal: true

require 'tmpdir'
require 'open3'

describe 'Invalid Config' do
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

  it 'with non hash validator config fails with clear error message' do
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

  it 'with non hash allvalidators fails with clear error message' do
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

  it 'with invalid per validator yardoptions type fails with clear error message' do
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

  it 'with invalid severity typo fails with did you mean suggestion' do
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

  it 'with unknown validator name fails with did you mean suggestion' do
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

  it 'with invalid enabled boolean fails with clear error message' do
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

  it 'with valid configuration runs successfully' do
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

  it 'with auto gen config and invalid config fails with clear error message' do
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


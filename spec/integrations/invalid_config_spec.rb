# frozen_string_literal: true

require 'tmpdir'
require 'open3'

RSpec.describe 'Invalid Configuration Integration' do
  let(:bin_path) { File.expand_path('../../bin/yard-lint', __dir__) }

  around do |example|
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # Create a sample Ruby file to lint
        File.write('test.rb', <<~RUBY)
          class Foo
            def bar
            end
          end
        RUBY
        example.run
      end
    end
  end

  context 'with non-Hash validator config' do
    it 'fails with clear error message' do
      File.write('.yard-lint.yml', <<~YAML)
        Tags/Order: true
      YAML

      output, status = Open3.capture2e(bin_path, 'test.rb')

      expect(status.exitstatus).to eq(1)
      expect(output).to include('Configuration Error')
      expect(output).to include("Invalid configuration for validator 'Tags/Order'")
      expect(output).to include('expected a Hash, got TrueClass')
    end
  end

  context 'with non-Hash AllValidators' do
    it 'fails with clear error message' do
      File.write('.yard-lint.yml', <<~YAML)
        AllValidators: true
      YAML

      output, status = Open3.capture2e(bin_path, 'test.rb')

      expect(status.exitstatus).to eq(1)
      expect(output).to include('Configuration Error')
      expect(output).to include('Invalid AllValidators: must be a Hash')
    end
  end

  context 'with invalid per-validator YardOptions type' do
    it 'fails with clear error message' do
      File.write('.yard-lint.yml', <<~YAML)
        Documentation/UndocumentedObjects:
          YardOptions: --private
      YAML

      output, status = Open3.capture2e(bin_path, 'test.rb')

      expect(status.exitstatus).to eq(1)
      expect(output).to include('Configuration Error')
      expect(output).to include('Invalid YardOptions for Documentation/UndocumentedObjects')
      expect(output).to include('must be an array')
    end
  end

  context 'with invalid severity typo' do
    it 'fails with did-you-mean suggestion' do
      File.write('.yard-lint.yml', <<~YAML)
        Documentation/UndocumentedObjects:
          Severity: erro
      YAML

      output, status = Open3.capture2e(bin_path, 'test.rb')

      expect(status.exitstatus).to eq(1)
      expect(output).to include('Configuration Error')
      expect(output).to include("Invalid Severity for Documentation/UndocumentedObjects: 'erro'")
      expect(output).to include('Did you mean: error?')
    end
  end

  context 'with unknown validator name' do
    it 'fails with did-you-mean suggestion' do
      File.write('.yard-lint.yml', <<~YAML)
        UndocumentedMethod:
          Enabled: true
      YAML

      output, status = Open3.capture2e(bin_path, 'test.rb')

      expect(status.exitstatus).to eq(1)
      expect(output).to include('Configuration Error')
      expect(output).to include("Unknown validator: 'UndocumentedMethod'")
    end
  end

  context 'with invalid Enabled boolean' do
    it 'fails with clear error message' do
      File.write('.yard-lint.yml', <<~YAML)
        Documentation/UndocumentedObjects:
          Enabled: "enabled"
      YAML

      output, status = Open3.capture2e(bin_path, 'test.rb')

      expect(status.exitstatus).to eq(1)
      expect(output).to include('Configuration Error')
      expect(output).to include("Invalid Enabled value for Documentation/UndocumentedObjects: 'enabled'")
      expect(output).to include('Must be true or false')
    end
  end

  context 'with valid configuration' do
    it 'runs successfully' do
      File.write('.yard-lint.yml', <<~YAML)
        AllValidators:
          Exclude:
            - spec/**/*
        Documentation/UndocumentedObjects:
          Enabled: false
      YAML

      output, status = Open3.capture2e(bin_path, 'test.rb')

      expect(status.exitstatus).to eq(0)
      expect(output).not_to include('Configuration Error')
    end
  end

  context 'with --auto-gen-config and invalid config' do
    it 'fails with clear error message' do
      File.write('.yard-lint.yml', <<~YAML)
        Tags/Order: invalid
      YAML

      output, status = Open3.capture2e(bin_path, '--auto-gen-config', 'test.rb')

      expect(status.exitstatus).to eq(1)
      expect(output).to include('Configuration Error')
      expect(output).to include("Invalid configuration for validator 'Tags/Order'")
    end
  end
end

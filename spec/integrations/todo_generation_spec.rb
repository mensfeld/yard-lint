# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'open3'

RSpec.describe 'Todo Generation Integration', :integration do
  let(:test_dir) { Dir.mktmpdir('yard-lint-todo-test') }
  let(:bin_path) { File.expand_path('../../bin/yard-lint', __dir__) }

  before do
    Dir.chdir(test_dir)
  end

  after do
    Dir.chdir('/')
    FileUtils.rm_rf(test_dir)
  end

  def run_yard_lint(*args)
    stdout, stderr, status = Open3.capture3(bin_path, *args)
    { stdout: stdout, stderr: stderr, exit_code: status.exitstatus }
  end

  def create_file_with_violations
    FileUtils.mkdir_p('lib')
    File.write('lib/example.rb', <<~RUBY)
      class Example
        def method_without_docs(param)
        end
      end
    RUBY
  end

  def create_multiple_files_with_violations
    FileUtils.mkdir_p('lib')
    5.times do |i|
      File.write("lib/file_#{i}.rb", <<~RUBY)
        class File#{i}
          def undocumented_method(arg)
          end
        end
      RUBY
    end
  end

  def create_clean_file
    FileUtils.mkdir_p('lib')
    File.write('lib/clean.rb', <<~RUBY)
      # Documentation for Clean
      class Clean
      end
    RUBY
  end

  describe '--auto-gen-config' do
    context 'with violations' do
      before { create_file_with_violations }

      it 'creates .yard-lint-todo.yml' do
        result = run_yard_lint('--auto-gen-config')

        expect(result[:exit_code]).to eq(0)
        expect(File.exist?('.yard-lint-todo.yml')).to be true
      end

      it 'displays success message' do
        result = run_yard_lint('--auto-gen-config')

        expect(result[:stdout]).to include('Created .yard-lint-todo.yml')
        expect(result[:stdout]).to include('Silenced')
        expect(result[:stdout]).to include('offense(s)')
      end

      it 'creates valid YAML with proper structure' do
        run_yard_lint('--auto-gen-config')

        expect { YAML.load_file('.yard-lint-todo.yml') }.not_to raise_error

        content = File.read('.yard-lint-todo.yml')
        expect(content).to include('# This file was auto-generated')
        expect(content).to include('# To gradually fix violations')
        expect(content).to include('Exclude:')
      end

      it 'includes validator exclusions' do
        run_yard_lint('--auto-gen-config')

        yaml = YAML.load_file('.yard-lint-todo.yml')

        # Should have at least one validator with Exclude list
        expect(yaml.keys.size).to be > 0

        yaml.each do |validator_name, config|
          expect(validator_name).to include('/')
          expect(config).to have_key('Exclude')
          expect(config['Exclude']).to be_an(Array)
        end
      end

      it 'creates or updates .yard-lint.yml to inherit from todo file' do
        run_yard_lint('--auto-gen-config')

        expect(File.exist?('.yard-lint.yml')).to be true

        config = YAML.load_file('.yard-lint.yml')
        expect(config['inherit_from']).to include('.yard-lint-todo.yml')
      end

      it 'uses relative paths in exclusions' do
        run_yard_lint('--auto-gen-config')

        yaml = YAML.load_file('.yard-lint-todo.yml')

        yaml.each_value do |config|
          config['Exclude'].each do |pattern|
            # Should not contain absolute paths
            expect(pattern).not_to start_with('/')
            expect(pattern).not_to include(test_dir)
          end
        end
      end

      it 'results in clean run after generation' do
        run_yard_lint('--auto-gen-config')

        # Run yard-lint again
        result = run_yard_lint('lib/')

        expect(result[:exit_code]).to eq(0)
        expect(result[:stdout]).to include('No offenses found')
      end
    end

    context 'with clean codebase' do
      before { create_clean_file }

      it 'does not create todo file' do
        result = run_yard_lint('--auto-gen-config')

        expect(result[:exit_code]).to eq(0)
        expect(File.exist?('.yard-lint-todo.yml')).to be false
      end

      it 'displays appropriate message' do
        result = run_yard_lint('--auto-gen-config')

        expect(result[:stdout]).to include('No offenses found')
        expect(result[:stdout]).to include('already compliant')
      end
    end

    context 'when todo file already exists' do
      before do
        create_file_with_violations
        File.write('.yard-lint-todo.yml', '# existing content')
      end

      it 'exits with error code 1' do
        result = run_yard_lint('--auto-gen-config')

        expect(result[:exit_code]).to eq(1)
      end

      it 'displays error message' do
        result = run_yard_lint('--auto-gen-config')

        expect(result[:stdout]).to include('Error')
        expect(result[:stdout]).to include('.yard-lint-todo.yml already exists')
        expect(result[:stdout]).to include('--regenerate-todo')
      end

      it 'does not overwrite existing file' do
        run_yard_lint('--auto-gen-config')

        content = File.read('.yard-lint-todo.yml')
        expect(content).to eq('# existing content')
      end
    end

    context 'when .yard-lint.yml already exists' do
      before do
        create_file_with_violations
        File.write('.yard-lint.yml', <<~YAML)
          AllValidators:
            Severity: warning
        YAML
      end

      it 'adds inherit_from to existing config' do
        run_yard_lint('--auto-gen-config')

        config = YAML.load_file('.yard-lint.yml')
        expect(config['inherit_from']).to include('.yard-lint-todo.yml')
        expect(config['AllValidators']).to eq({ 'Severity' => 'warning' })
      end

      it 'does not duplicate inherit_from entry on multiple runs' do
        run_yard_lint('--auto-gen-config')
        File.delete('.yard-lint-todo.yml')
        run_yard_lint('--auto-gen-config')

        config = YAML.load_file('.yard-lint.yml')
        count = config['inherit_from'].count('.yard-lint-todo.yml')
        expect(count).to eq(1)
      end
    end

    context 'with multiple violations across validators' do
      before do
        FileUtils.mkdir_p('lib')
        File.write('lib/multi.rb', <<~RUBY)
          class Multi
            # @param invalid_name
            def foo(real_param)
            end

            def undocumented
            end
          end
        RUBY
      end

      it 'creates separate exclusions for each validator' do
        run_yard_lint('--auto-gen-config')

        yaml = YAML.load_file('.yard-lint-todo.yml')

        # Should have multiple validators
        expect(yaml.keys.size).to be > 1
      end

      it 'groups validators by category' do
        run_yard_lint('--auto-gen-config')

        content = File.read('.yard-lint-todo.yml')

        # Should have category comments
        expect(content).to include('# Documentation validators')
      end
    end

    context 'with path argument' do
      before do
        FileUtils.mkdir_p('lib')
        FileUtils.mkdir_p('app')

        File.write('lib/test.rb', <<~RUBY)
          class Test
          end
        RUBY

        File.write('app/other.rb', <<~RUBY)
          class Other
          end
        RUBY
      end

      it 'generates todo file for specified path only' do
        result = run_yard_lint('--auto-gen-config', 'lib/')

        expect(result[:exit_code]).to eq(0)
        expect(File.exist?('.yard-lint-todo.yml')).to be true
      end
    end
  end

  describe '--regenerate-todo' do
    before do
      create_file_with_violations
      File.write('.yard-lint-todo.yml', '# existing content')
    end

    it 'overwrites existing todo file' do
      result = run_yard_lint('--regenerate-todo')

      expect(result[:exit_code]).to eq(0)
      content = File.read('.yard-lint-todo.yml')
      expect(content).not_to eq('# existing content')
      expect(content).to include('# This file was auto-generated')
    end

    it 'displays success message' do
      result = run_yard_lint('--regenerate-todo')

      expect(result[:stdout]).to include('Created .yard-lint-todo.yml')
    end
  end

  describe '--exclude-limit' do
    before { create_multiple_files_with_violations }

    it 'accepts custom exclude limit' do
      result = run_yard_lint('--auto-gen-config', '--exclude-limit', '3')

      expect(result[:exit_code]).to eq(0)
      expect(File.exist?('.yard-lint-todo.yml')).to be true
    end

    it 'affects grouping behavior' do
      # With high limit, should keep individual files
      run_yard_lint('--auto-gen-config', '--exclude-limit', '100')

      yaml = YAML.load_file('.yard-lint-todo.yml')
      all_patterns = yaml.values.flat_map { |v| v['Exclude'] }

      # Should have individual files, not patterns
      expect(all_patterns.any? { |p| p.include?('file_0.rb') }).to be true
    end
  end

  describe '--help' do
    it 'includes --auto-gen-config in the help text' do
      result = run_yard_lint('--help')

      expect(result[:stdout]).to include('--auto-gen-config')
      expect(result[:stdout]).to include('silence existing violations')
    end

    it 'includes --regenerate-todo in the help text' do
      result = run_yard_lint('--help')

      expect(result[:stdout]).to include('--regenerate-todo')
    end

    it 'includes --exclude-limit in the help text' do
      result = run_yard_lint('--help')

      expect(result[:stdout]).to include('--exclude-limit')
    end

    it 'includes examples in the help text' do
      result = run_yard_lint('--help')

      expect(result[:stdout]).to include('yard-lint --auto-gen-config')
      expect(result[:stdout]).to include('yard-lint --regenerate-todo')
    end
  end

  describe 'incremental workflow' do
    before { create_file_with_violations }

    it 'allows removing entries to re-expose violations' do
      # Generate todo file
      run_yard_lint('--auto-gen-config')

      # Verify clean run
      result = run_yard_lint('lib/')
      expect(result[:stdout]).to include('No offenses found')

      # Remove an entry from todo file
      yaml = YAML.load_file('.yard-lint-todo.yml')
      first_validator = yaml.keys.first
      yaml[first_validator]['Exclude'] = []
      File.write('.yard-lint-todo.yml', yaml.to_yaml)

      # Run again - should now show violations
      result = run_yard_lint('lib/')
      expect(result[:exit_code]).not_to eq(0)
      expect(result[:stdout]).to include('offense(s)')
    end
  end

  describe 'YAML formatting' do
    before { create_file_with_violations }

    it 'includes header with generation timestamp' do
      run_yard_lint('--auto-gen-config')

      content = File.read('.yard-lint-todo.yml')
      expect(content).to match(/# This file was auto-generated by yard-lint --auto-gen-config on \d{4}-\d{2}-\d{2}/)
    end

    it 'includes helpful comments' do
      run_yard_lint('--auto-gen-config')

      content = File.read('.yard-lint-todo.yml')
      expect(content).to include('To gradually fix violations')
      expect(content).to include('yard-lint --regenerate-todo')
    end

    it 'maintains proper category ordering' do
      run_yard_lint('--auto-gen-config')

      content = File.read('.yard-lint-todo.yml')

      # Find positions of validators
      doc_validators = content.scan(/^Documentation\/\w+:/)
      tags_validators = content.scan(/^Tags\/\w+:/)

      # If both exist, Documentation should come before Tags
      if doc_validators.any? && tags_validators.any?
        doc_pos = content.index(doc_validators.first)
        tags_pos = content.index(tags_validators.first)
        expect(doc_pos).to be < tags_pos
      end
    end
  end

  describe 'error handling' do
    it 'handles non-existent paths gracefully' do
      result = run_yard_lint('--auto-gen-config', 'non_existent/')

      expect(result[:exit_code]).to eq(1)
      expect(result[:stdout]).to include('Error')
    end
  end
end

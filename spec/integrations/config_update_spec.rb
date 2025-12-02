# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'open3'

RSpec.describe 'Config Update Integration', :integration do
  let(:test_dir) { Dir.mktmpdir }
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

  describe '--update' do
    context 'when config file does not exist' do
      it 'exits with error code 1' do
        result = run_yard_lint('--update')

        expect(result[:exit_code]).to eq(1)
      end

      it 'displays helpful error message' do
        result = run_yard_lint('--update')

        expect(result[:stdout]).to include('Config file not found')
        expect(result[:stdout]).to include('Use --init to create one')
      end
    end

    context 'when config file exists and is up to date' do
      before do
        run_yard_lint('--init')
      end

      it 'exits with success code 0' do
        result = run_yard_lint('--update')

        expect(result[:exit_code]).to eq(0)
      end

      it 'reports that config is up to date' do
        result = run_yard_lint('--update')

        expect(result[:stdout]).to include('already up to date')
      end
    end

    context 'when config file is missing validators' do
      before do
        File.write('.yard-lint.yml', <<~YAML)
          AllValidators:
            Exclude:
              - 'vendor/**/*'

          Documentation/UndocumentedObjects:
            Enabled: true
            Severity: error
        YAML
      end

      it 'exits with success code 0' do
        result = run_yard_lint('--update')

        expect(result[:exit_code]).to eq(0)
      end

      it 'reports added validators' do
        result = run_yard_lint('--update')

        expect(result[:stdout]).to include('Updated .yard-lint.yml')
        expect(result[:stdout]).to include('Added')
        expect(result[:stdout]).to include('new validator')
      end

      it 'reports preserved validators' do
        result = run_yard_lint('--update')

        expect(result[:stdout]).to include('Preserved 1 existing validator')
      end

      it 'preserves user settings in the file' do
        run_yard_lint('--update')

        updated_config = YAML.load_file('.yard-lint.yml')
        expect(updated_config['Documentation/UndocumentedObjects']['Severity']).to eq('error')
      end

      it 'adds missing validators to the file' do
        run_yard_lint('--update')

        updated_config = YAML.load_file('.yard-lint.yml')
        expect(updated_config).to have_key('Tags/Order')
        expect(updated_config).to have_key('Tags/TypeSyntax')
        expect(updated_config).to have_key('Warnings/UnknownTag')
      end

      it 'produces valid YAML' do
        run_yard_lint('--update')

        expect { YAML.load_file('.yard-lint.yml') }.not_to raise_error
      end
    end

    context 'when config file has obsolete validators' do
      before do
        # Create a full config then add an obsolete validator
        run_yard_lint('--init')

        content = File.read('.yard-lint.yml')
        content += <<~YAML

          Obsolete/FakeValidator:
            Enabled: true
            Severity: warning
        YAML
        File.write('.yard-lint.yml', content)
      end

      it 'reports removed validators' do
        result = run_yard_lint('--update')

        expect(result[:stdout]).to include('Removed')
        expect(result[:stdout]).to include('Obsolete/FakeValidator')
      end

      it 'removes obsolete validators from the file' do
        run_yard_lint('--update')

        updated_config = YAML.load_file('.yard-lint.yml')
        expect(updated_config).not_to have_key('Obsolete/FakeValidator')
      end
    end

    context 'with --strict flag' do
      before do
        File.write('.yard-lint.yml', <<~YAML)
          AllValidators:
            Exclude: []

          Documentation/UndocumentedObjects:
            Enabled: true
        YAML
      end

      it 'uses strict template defaults for new validators' do
        run_yard_lint('--update', '--strict')

        updated_config = YAML.load_file('.yard-lint.yml')

        # Check that new validators were added
        expect(updated_config).to have_key('Tags/Order')
      end
    end

    context 'with YAML output formatting' do
      before do
        File.write('.yard-lint.yml', 'AllValidators: {}')
      end

      it 'includes header comment' do
        run_yard_lint('--update')

        content = File.read('.yard-lint.yml')
        expect(content).to include('# YARD-Lint Configuration')
      end

      it 'includes category comments' do
        run_yard_lint('--update')

        content = File.read('.yard-lint.yml')
        expect(content).to include('# Documentation validators')
        expect(content).to include('# Tags validators')
        expect(content).to include('# Warnings validators')
        expect(content).to include('# Semantic validators')
      end

      it 'maintains proper category ordering' do
        run_yard_lint('--update')

        content = File.read('.yard-lint.yml')

        # Documentation should come before Tags
        doc_pos = content.index('# Documentation validators')
        tags_pos = content.index('# Tags validators')
        warnings_pos = content.index('# Warnings validators')
        semantic_pos = content.index('# Semantic validators')

        expect(doc_pos).to be < tags_pos
        expect(tags_pos).to be < warnings_pos
        expect(warnings_pos).to be < semantic_pos
      end
    end
  end

  describe '--help' do
    it 'includes --update in the help text' do
      result = run_yard_lint('--help')

      expect(result[:stdout]).to include('--update')
      expect(result[:stdout]).to include('add new validators')
    end

    it 'includes --update in the examples' do
      result = run_yard_lint('--help')

      expect(result[:stdout]).to include('yard-lint --update')
    end
  end

  describe 'workflow: --init then --update' do
    it 'works correctly when config was just initialized' do
      init_result = run_yard_lint('--init')
      expect(init_result[:exit_code]).to eq(0)

      update_result = run_yard_lint('--update')
      expect(update_result[:exit_code]).to eq(0)
      expect(update_result[:stdout]).to include('already up to date')
    end
  end
end

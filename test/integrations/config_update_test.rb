# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'open3'

describe 'Config Update' do
  attr_reader :test_dir, :bin_path, :original_dir

  before do
    @original_dir = Dir.pwd
    @test_dir = Dir.mktmpdir
    @bin_path = File.expand_path('../../bin/yard-lint', __dir__)
    Dir.chdir(@test_dir)
  end

  after do
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@test_dir)
  end

  def run_yard_lint(*args)
    stdout, stderr, status = Open3.capture3(@bin_path, *args)
    { stdout: stdout, stderr: stderr, exit_code: status.exitstatus }
  end

  # -- update when config file does not exist --

  it 'update when config does not exist exits with error code 1' do
    result = run_yard_lint('--update')

    assert_equal(1, result[:exit_code])
  end

  it 'update when config does not exist displays helpful error message' do
    result = run_yard_lint('--update')

    assert_includes(result[:stdout], 'Config file not found')
    assert_includes(result[:stdout], 'Use --init to create one')
  end

  # -- update when config file exists and is up to date --

  it 'update when config exists and is up to date exits with success code 0' do
    run_yard_lint('--init')
    result = run_yard_lint('--update')

    assert_equal(0, result[:exit_code])
  end

  it 'update when config exists and is up to date reports config is up to date' do
    run_yard_lint('--init')
    result = run_yard_lint('--update')

    assert_includes(result[:stdout], 'already up to date')
  end

  # -- update when config file is missing validators --

  def write_partial_config
    File.write('.yard-lint.yml', <<~YAML)
      AllValidators:
        Exclude:
          - 'vendor/**/*'

      Documentation/UndocumentedObjects:
        Enabled: true
        Severity: error
    YAML
  end

  it 'update when missing validators exits with success code 0' do
    write_partial_config
    result = run_yard_lint('--update')

    assert_equal(0, result[:exit_code])
  end

  it 'update when missing validators reports added validators' do
    write_partial_config
    result = run_yard_lint('--update')

    assert_includes(result[:stdout], 'Updated .yard-lint.yml')
    assert_includes(result[:stdout], 'Added')
    assert_includes(result[:stdout], 'new validator')
  end

  it 'update when missing validators reports preserved validators' do
    write_partial_config
    result = run_yard_lint('--update')

    assert_includes(result[:stdout], 'Preserved 1 existing validator')
  end

  it 'update when missing validators preserves user settings in the file' do
    write_partial_config
    run_yard_lint('--update')

    updated_config = YAML.load_file('.yard-lint.yml')
    assert_equal('error', updated_config['Documentation/UndocumentedObjects']['Severity'])
  end

  it 'update when missing validators adds missing validators to the file' do
    write_partial_config
    run_yard_lint('--update')

    updated_config = YAML.load_file('.yard-lint.yml')
    assert(updated_config.key?('Tags/Order'))
    assert(updated_config.key?('Tags/TypeSyntax'))
    assert(updated_config.key?('Warnings/UnknownTag'))
  end

  it 'update when missing validators produces valid yaml' do
    write_partial_config
    run_yard_lint('--update')

    YAML.load_file('.yard-lint.yml')
  end

  # -- update when config file has obsolete validators --

  def write_config_with_obsolete_validator
    run_yard_lint('--init')

    content = File.read('.yard-lint.yml')
    content += <<~YAML

      Obsolete/FakeValidator:
        Enabled: true
        Severity: warning
    YAML
    File.write('.yard-lint.yml', content)
  end

  it 'update when obsolete validators reports removed validators' do
    write_config_with_obsolete_validator
    result = run_yard_lint('--update')

    assert_includes(result[:stdout], 'Removed')
    assert_includes(result[:stdout], 'Obsolete/FakeValidator')
  end

  it 'update when obsolete validators removes obsolete validators from the file' do
    write_config_with_obsolete_validator
    run_yard_lint('--update')

    updated_config = YAML.load_file('.yard-lint.yml')
    refute(updated_config.key?('Obsolete/FakeValidator'))
  end

  # -- update with --strict flag --

  it 'update with strict flag uses strict template defaults for new validators' do
    File.write('.yard-lint.yml', <<~YAML)
      AllValidators:
        Exclude: []

      Documentation/UndocumentedObjects:
        Enabled: true
    YAML

    run_yard_lint('--update', '--strict')

    updated_config = YAML.load_file('.yard-lint.yml')

    # Check that new validators were added
    assert(updated_config.key?('Tags/Order'))
  end

  # -- YAML output formatting --

  def write_minimal_config
    File.write('.yard-lint.yml', 'AllValidators: {}')
  end

  it 'update yaml formatting includes header comment' do
    write_minimal_config
    run_yard_lint('--update')

    content = File.read('.yard-lint.yml')
    assert_includes(content, '# YARD-Lint Configuration')
  end

  it 'update yaml formatting includes category comments' do
    write_minimal_config
    run_yard_lint('--update')

    content = File.read('.yard-lint.yml')
    assert_includes(content, '# Documentation validators')
    assert_includes(content, '# Tags validators')
    assert_includes(content, '# Warnings validators')
    assert_includes(content, '# Semantic validators')
  end

  it 'update yaml formatting maintains proper category ordering' do
    write_minimal_config
    run_yard_lint('--update')

    content = File.read('.yard-lint.yml')

    # Documentation should come before Tags
    doc_pos = content.index('# Documentation validators')
    tags_pos = content.index('# Tags validators')
    warnings_pos = content.index('# Warnings validators')
    semantic_pos = content.index('# Semantic validators')

    assert_operator(doc_pos, :<, tags_pos)
    assert_operator(tags_pos, :<, warnings_pos)
    assert_operator(warnings_pos, :<, semantic_pos)
  end

  # -- help --

  it 'help includes update in the help text' do
    result = run_yard_lint('--help')

    assert_includes(result[:stdout], '--update')
    assert_includes(result[:stdout], 'add new validators')
  end

  it 'help includes update in the examples' do
    result = run_yard_lint('--help')

    assert_includes(result[:stdout], 'yard-lint --update')
  end

  # -- workflow: init then update --

  it 'workflow init then update works correctly' do
    init_result = run_yard_lint('--init')
    assert_equal(0, init_result[:exit_code])

    update_result = run_yard_lint('--update')
    assert_equal(0, update_result[:exit_code])
    assert_includes(update_result[:stdout], 'already up to date')
  end
end


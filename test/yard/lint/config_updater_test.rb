# frozen_string_literal: true

require 'test_helper'


describe 'Yard::Lint::ConfigUpdater' do
  attr_reader :fixtures_dir, :config_path

  before do
    @fixtures_dir = File.expand_path('../../fixtures', __dir__)
    @config_path = File.join(@fixtures_dir, '.yard-lint.yml')
    FileUtils.mkdir_p(@fixtures_dir)
  end

  after do
    FileUtils.rm_f(@config_path)
  end

  it 'update when config file does not exist raises configfilenotfounderror' do
    error = assert_raises(Yard::Lint::Errors::ConfigFileNotFoundError) do
      Yard::Lint::ConfigUpdater.update(path: @config_path)
    end
    assert_match(/Config file not found/, error.message)
  end

  it 'update when config file does not exist suggests using init' do
    error = assert_raises(Yard::Lint::Errors::ConfigFileNotFoundError) do
      Yard::Lint::ConfigUpdater.update(path: @config_path)
    end
    assert_match(/Use --init to create one/, error.message)
  end

  it 'update with all current validators present reports no changes needed' do
    template_path = File.join(Yard::Lint::ConfigUpdater::TEMPLATES_DIR, 'default_config.yml')
    FileUtils.cp(template_path, @config_path)

    result = Yard::Lint::ConfigUpdater.update(path: @config_path)

    assert_empty(result[:added])
    assert_empty(result[:removed])
  end

  it 'update with all current validators present returns all validators as preserved' do
    template_path = File.join(Yard::Lint::ConfigUpdater::TEMPLATES_DIR, 'default_config.yml')
    FileUtils.cp(template_path, @config_path)

    result = Yard::Lint::ConfigUpdater.update(path: @config_path)

    assert_equal(Yard::Lint::ConfigLoader::ALL_VALIDATORS.sort, result[:preserved])
  end

  it 'update with missing validators adds new validators with default config' do
    File.write(@config_path, <<~YAML)
      AllValidators:
        Exclude:
          - 'vendor/**/*'

      Documentation/UndocumentedObjects:
        Enabled: true
        Severity: error
    YAML

    result = Yard::Lint::ConfigUpdater.update(path: @config_path)

    assert_includes(result[:added], 'Tags/Order')
    assert_includes(result[:added], 'Tags/TypeSyntax')
  end

  it 'update with missing validators preserves existing validators' do
    File.write(@config_path, <<~YAML)
      AllValidators:
        Exclude:
          - 'vendor/**/*'

      Documentation/UndocumentedObjects:
        Enabled: true
        Severity: error
    YAML

    result = Yard::Lint::ConfigUpdater.update(path: @config_path)

    assert_equal(['Documentation/UndocumentedObjects'], result[:preserved])
  end

  it 'update with missing validators preserves user settings for existing validators' do
    File.write(@config_path, <<~YAML)
      AllValidators:
        Exclude:
          - 'vendor/**/*'

      Documentation/UndocumentedObjects:
        Enabled: true
        Severity: error
    YAML

    Yard::Lint::ConfigUpdater.update(path: @config_path)

    updated = YAML.load_file(@config_path)
    assert_equal('error', updated['Documentation/UndocumentedObjects']['Severity'])
  end

  it 'update with missing validators writes valid yaml' do
    File.write(@config_path, <<~YAML)
      AllValidators:
        Exclude:
          - 'vendor/**/*'

      Documentation/UndocumentedObjects:
        Enabled: true
        Severity: error
    YAML

    Yard::Lint::ConfigUpdater.update(path: @config_path)

    YAML.load_file(@config_path)
  end

  it 'update with obsolete validators removes obsolete validators' do
    template_path = File.join(Yard::Lint::ConfigUpdater::TEMPLATES_DIR, 'default_config.yml')
    template_content = File.read(template_path)
    obsolete_content = template_content + <<~YAML

      Obsolete/FakeValidator:
        Enabled: true
        Severity: warning
    YAML
    File.write(@config_path, obsolete_content)

    result = Yard::Lint::ConfigUpdater.update(path: @config_path)

    assert_equal(['Obsolete/FakeValidator'], result[:removed])
  end

  it 'update with obsolete validators does not include obsolete validators in output' do
    template_path = File.join(Yard::Lint::ConfigUpdater::TEMPLATES_DIR, 'default_config.yml')
    template_content = File.read(template_path)
    obsolete_content = template_content + <<~YAML

      Obsolete/FakeValidator:
        Enabled: true
        Severity: warning
    YAML
    File.write(@config_path, obsolete_content)

    Yard::Lint::ConfigUpdater.update(path: @config_path)

    updated = YAML.load_file(@config_path)
    refute(updated.key?('Obsolete/FakeValidator'))
  end

  it 'update with partial validator config merges with template defaults' do
    File.write(@config_path, <<~YAML)
      AllValidators:
        Exclude: []

      Tags/Order:
        Enabled: false
    YAML

    Yard::Lint::ConfigUpdater.update(path: @config_path)

    updated = YAML.load_file(@config_path)

    # User setting preserved
    assert_equal(false, updated['Tags/Order']['Enabled'])
    # Template default merged in
    assert_kind_of(Array, updated['Tags/Order']['EnforcedOrder'])
    assert_kind_of(String, updated['Tags/Order']['Description'])
  end

  it 'update with empty config file adds all validators' do
    File.write(@config_path, '')

    result = Yard::Lint::ConfigUpdater.update(path: @config_path)

    assert_equal(Yard::Lint::ConfigLoader::ALL_VALIDATORS.size, result[:added].size)
    assert_empty(result[:preserved])
  end

  it 'update with strict mode uses strict template defaults for new validators' do
    File.write(@config_path, <<~YAML)
      AllValidators:
        Exclude: []

      Documentation/UndocumentedObjects:
        Enabled: true
    YAML

    Yard::Lint::ConfigUpdater.update(path: @config_path, strict: true)

    updated = YAML.load_file(@config_path)

    # New validators should use strict template
    assert_kind_of(Hash, updated['Tags/Order'])
  end

  it 'update includes header comments' do
    File.write(@config_path, <<~YAML)
      AllValidators:
        Exclude: []
    YAML

    Yard::Lint::ConfigUpdater.update(path: @config_path)

    content = File.read(@config_path)
    assert_includes(content, '# YARD-Lint Configuration')
  end

  it 'update includes category comments' do
    File.write(@config_path, <<~YAML)
      AllValidators:
        Exclude: []
    YAML

    Yard::Lint::ConfigUpdater.update(path: @config_path)

    content = File.read(@config_path)
    assert_includes(content, '# Documentation validators')
    assert_includes(content, '# Tags validators')
    assert_includes(content, '# Warnings validators')
    assert_includes(content, '# Semantic validators')
  end

  it 'update groups validators by category' do
    File.write(@config_path, <<~YAML)
      AllValidators:
        Exclude: []
    YAML

    Yard::Lint::ConfigUpdater.update(path: @config_path)

    content = File.read(@config_path)

    # Documentation validators should come before Tags validators
    doc_pos = content.index('Documentation/UndocumentedObjects:')
    tags_pos = content.index('Tags/Order:')
    assert_operator(doc_pos, :<, tags_pos)
  end

  it 'update preserves allvalidators section' do
    File.write(@config_path, <<~YAML)
      AllValidators:
        Exclude: []
    YAML

    Yard::Lint::ConfigUpdater.update(path: @config_path)

    updated = YAML.load_file(@config_path)
    assert(updated.key?('AllValidators'))
  end

  it 'initialize uses default path when none provided' do
    Dir.chdir(@fixtures_dir) do
      File.write('.yard-lint.yml', 'AllValidators: {}')
      updater = Yard::Lint::ConfigUpdater.new
      updater.update
      File.delete('.yard-lint.yml')
    end
  end

  it 'initialize uses provided path' do
    custom_path = File.join(@fixtures_dir, 'custom_config.yml')
    File.write(custom_path, 'AllValidators: {}')

    result = Yard::Lint::ConfigUpdater.update(path: custom_path)

    assert_kind_of(Hash, result)
  ensure
    FileUtils.rm_f(custom_path) if custom_path
  end
end

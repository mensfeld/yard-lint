# frozen_string_literal: true

describe 'Yard::Lint::ConfigGenerator' do
  attr_reader :temp_dir, :config_path, :original_dir

  before do
    @temp_dir = Dir.mktmpdir
    @config_path = File.join(@temp_dir, '.yard-lint.yml')
    @original_dir = Dir.pwd
    Dir.chdir(@temp_dir)
  end

  after do
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@temp_dir)
  end

  it 'creates yard lint yml file' do
    assert_equal(false, File.exist?(@config_path))

    result = Yard::Lint::ConfigGenerator.generate

    assert_equal(true, result)
    assert_equal(true, File.exist?(@config_path))
  end

  it 'creates file with yard lint configuration header' do
    Yard::Lint::ConfigGenerator.generate

    content = File.read(@config_path)
    assert_includes(content, '# YARD-Lint Configuration')
    assert_includes(content, '# See https://github.com/mensfeld/yard-lint for documentation')
  end

  it 'creates file with allvalidators section' do
    Yard::Lint::ConfigGenerator.generate

    content = File.read(@config_path)
    assert_includes(content, 'AllValidators:')
    assert_includes(content, 'YardOptions:')
    assert_includes(content, 'Exclude:')
    assert_includes(content, 'FailOnSeverity: warning')
  end

  it 'creates file with all discovered validator configurations' do
    Yard::Lint::ConfigGenerator.generate

    content = File.read(@config_path)

    # Dynamically check all validators from ConfigLoader
    Yard::Lint::ConfigLoader::ALL_VALIDATORS.each do |validator_name|
      assert_includes(content, "#{validator_name}:",
        "Expected config to include #{validator_name}")
        end
  end

  it 'creates file with default exclusions' do
    Yard::Lint::ConfigGenerator.generate

    content = File.read(@config_path)
    assert_includes(content, "- '\\.git'")
    assert_includes(content, "- 'vendor/**/*'")
    assert_includes(content, "- 'node_modules/**/*'")
    assert_includes(content, "- 'spec/**/*'")
    assert_includes(content, "- 'test/**/*'")
  end

  it 'creates file with yard options' do
    Yard::Lint::ConfigGenerator.generate

    content = File.read(@config_path)
    assert_includes(content, '- --private')
    assert_includes(content, '- --protected')
  end

  it 'when config file already exists returns false without overwriting' do
    File.write(@config_path, '# Existing config')

    result = Yard::Lint::ConfigGenerator.generate

    assert_equal(false, result)
    assert_equal('# Existing config', File.read(@config_path))
  end

  it 'when config file already exists with force overwrites existing file' do
    File.write(@config_path, '# Existing config')

    result = Yard::Lint::ConfigGenerator.generate(force: true)

    assert_equal(true, result)
    content = File.read(@config_path)
    assert_includes(content, '# YARD-Lint Configuration')
    refute_equal('# Existing config', content)
  end

  it 'generates valid yaml' do
    Yard::Lint::ConfigGenerator.generate

    YAML.load_file(@config_path)
  end

  it 'generates parseable config' do
    Yard::Lint::ConfigGenerator.generate

    config_hash = YAML.load_file(@config_path)
    assert_kind_of(Hash, config_hash)
    assert(config_hash.key?('AllValidators'))
    assert(config_hash['AllValidators'].key?('YardOptions'))
    assert(config_hash['AllValidators'].key?('Exclude'))
    assert(config_hash['AllValidators'].key?('FailOnSeverity'))
  end
end


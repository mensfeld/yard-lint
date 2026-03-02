# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::ConfigLoader' do
  attr_reader :config_dir, :config_path

  before do
    @config_dir = File.expand_path('../../../fixtures', __dir__)
    @config_path = File.join(config_dir, 'test_config.yml')
    FileUtils.mkdir_p(config_dir)
  end

  after do
    FileUtils.rm_f(config_path)
  end

  # .load (class method)

  it 'load loads a configuration file' do
    config_path_local = File.join(config_dir, 'basic_config.yml')
    File.write(config_path_local, "AllValidators:\n  Exclude:\n    - 'vendor/**/*'")

    config = Yard::Lint::ConfigLoader.load(config_path_local)

    assert_kind_of(Hash, config)
    assert_equal(['vendor/**/*'], config['AllValidators']['Exclude'])

    File.delete(config_path_local)
  end

  # .validator_module

  it 'validator module returns the correct module for tags order' do
    assert_equal(Yard::Lint::Validators::Tags::Order, Yard::Lint::ConfigLoader.validator_module('Tags/Order'))
  end

  it 'validator module returns the correct module for tags invalidtypes' do
    assert_equal(Yard::Lint::Validators::Tags::InvalidTypes, Yard::Lint::ConfigLoader.validator_module('Tags/InvalidTypes'))
  end

  it 'validator module returns the correct module for tags apitags' do
    assert_equal(Yard::Lint::Validators::Tags::ApiTags, Yard::Lint::ConfigLoader.validator_module('Tags/ApiTags'))
  end

  it 'validator module returns the correct module for documentation undocumentedmethodarguments' do
    assert_equal(
      Yard::Lint::Validators::Documentation::UndocumentedMethodArguments,
      Yard::Lint::ConfigLoader.validator_module('Documentation/UndocumentedMethodArguments')
    )
  end

  it 'validator module returns the correct module for semantic abstractmethods' do
    assert_equal(
      Yard::Lint::Validators::Semantic::AbstractMethods,
      Yard::Lint::ConfigLoader.validator_module('Semantic/AbstractMethods')
    )
  end

  it 'validator module returns the correct module for warnings unknowntag' do
    assert_equal(
      Yard::Lint::Validators::Warnings::UnknownTag,
      Yard::Lint::ConfigLoader.validator_module('Warnings/UnknownTag')
    )
  end

  it 'validator module returns the correct module for documentation undocumentedobjects' do
    assert_equal(
      Yard::Lint::Validators::Documentation::UndocumentedObjects,
      Yard::Lint::ConfigLoader.validator_module('Documentation/UndocumentedObjects')
    )
  end

  it 'validator module returns nil for non existent validators' do
    assert_nil(Yard::Lint::ConfigLoader.validator_module('Tags/NonExistent'))
  end

  # #load (instance method)

  it 'load loads a simple configuration' do
    File.write(config_path, <<~YAML)
      AllValidators:
        Exclude:
          - 'test/**/*'
    YAML

    loader = Yard::Lint::ConfigLoader.new(config_path)
    config = loader.load

    assert_equal(['test/**/*'], config['AllValidators']['Exclude'])
  end

  it 'load handles empty configuration files' do
    File.write(config_path, '')

    loader = Yard::Lint::ConfigLoader.new(config_path)
    config = loader.load

    assert_equal({}, config)
  end

  it 'load merges inherited configurations with inherit from' do
    base_config_path = File.join(config_dir, 'base_config.yml')
    File.write(base_config_path, <<~YAML)
      AllValidators:
        Exclude:
          - 'base/**/*'
    YAML

    File.write(config_path, <<~YAML)
      inherit_from: base_config.yml
      AllValidators:
        FailOnSeverity: error
    YAML

    loader = Yard::Lint::ConfigLoader.new(config_path)
    config = loader.load

    assert_equal(['base/**/*'], config['AllValidators']['Exclude'])
    assert_equal('error', config['AllValidators']['FailOnSeverity'])

    FileUtils.rm_f(base_config_path)
  end

  it 'load handles multiple inherited files with inherit from' do
    base1_path = File.join(config_dir, 'base1.yml')
    base2_path = File.join(config_dir, 'base2.yml')

    File.write(base1_path, <<~YAML)
      Tags/Order:
        Enabled: false
    YAML

    File.write(base2_path, <<~YAML)
      Tags/InvalidTypes:
        Enabled: false
    YAML

    File.write(config_path, <<~YAML)
      inherit_from:
        - base1.yml
        - base2.yml
    YAML

    loader = Yard::Lint::ConfigLoader.new(config_path)
    config = loader.load

    assert_equal(false, config['Tags/Order']['Enabled'])
    assert_equal(false, config['Tags/InvalidTypes']['Enabled'])

    FileUtils.rm_f([base1_path, base2_path])
  end

  it 'load raises error on circular dependencies' do
    circular1_path = File.join(config_dir, 'circular1.yml')
    circular2_path = File.join(config_dir, 'circular2.yml')

    File.write(circular1_path, <<~YAML)
      inherit_from: circular2.yml
    YAML

    File.write(circular2_path, <<~YAML)
      inherit_from: circular1.yml
    YAML

    loader = Yard::Lint::ConfigLoader.new(circular1_path)

    assert_raises(Yard::Lint::Errors::CircularDependencyError) { loader.load }

    FileUtils.rm_f([circular1_path, circular2_path])
  end

  it 'load overrides inherited array values completely' do
    base_config_path = File.join(config_dir, 'base_config.yml')
    File.write(base_config_path, <<~YAML)
      AllValidators:
        Exclude:
          - 'vendor/**/*'
          - 'node_modules/**/*'
    YAML

    File.write(config_path, <<~YAML)
      inherit_from: base_config.yml
      AllValidators:
        Exclude:
          - 'test/**/*'
    YAML

    loader = Yard::Lint::ConfigLoader.new(config_path)
    config = loader.load

    # Arrays should be completely replaced, not merged
    assert_equal(['test/**/*'], config['AllValidators']['Exclude'])

    FileUtils.rm_f(base_config_path)
  end

  it 'load merges hash values deeply' do
    base_config_path = File.join(config_dir, 'base_config.yml')
    File.write(base_config_path, <<~YAML)
      Tags/Order:
        Enabled: true
        Severity: convention
    YAML

    File.write(config_path, <<~YAML)
      inherit_from: base_config.yml
      Tags/Order:
        Severity: warning
    YAML

    loader = Yard::Lint::ConfigLoader.new(config_path)
    config = loader.load

    assert_equal(true, config['Tags/Order']['Enabled'])
    assert_equal('warning', config['Tags/Order']['Severity'])

    FileUtils.rm_f(base_config_path)
  end

  it 'load skips non existent inherited files' do
    File.write(config_path, <<~YAML)
      inherit_from: non_existent.yml
      AllValidators:
        FailOnSeverity: error
    YAML

    loader = Yard::Lint::ConfigLoader.new(config_path)
    config = loader.load

    assert_equal('error', config['AllValidators']['FailOnSeverity'])
  end

  # gem inheritance

  it 'gem inheritance handles missing gems gracefully' do
    gem_config_path = File.join(config_dir, 'test_gem_config.yml')
    File.write(gem_config_path, <<~YAML)
      inherit_gem:
        non_existent_gem: config.yml
    YAML

    loader = Yard::Lint::ConfigLoader.new(gem_config_path)

    loader.load

    FileUtils.rm_f(gem_config_path)
  end

  # merge behavior

  it 'merge behavior does not include inherit from in merged config' do
    merge_config_path = File.join(config_dir, 'merge_test.yml')
    File.write(merge_config_path, <<~YAML)
      inherit_from: base.yml
      AllValidators:
        Exclude:
          - 'test/**/*'
    YAML

    loader = Yard::Lint::ConfigLoader.new(merge_config_path)
    config = loader.load

    assert_equal(false, config.key?('inherit_from'))

    FileUtils.rm_f(merge_config_path)
  end

  it 'merge behavior does not include inherit gem in merged config' do
    merge_config_path = File.join(config_dir, 'merge_test.yml')
    File.write(merge_config_path, <<~YAML)
      inherit_gem:
        some_gem: config.yml
      AllValidators:
        Exclude:
          - 'test/**/*'
    YAML

    loader = Yard::Lint::ConfigLoader.new(merge_config_path)
    config = loader.load

    assert_equal(false, config.key?('inherit_gem'))

    FileUtils.rm_f(merge_config_path)
  end

  it 'merge behavior merges scalar values by overriding' do
    base_config_path = File.join(config_dir, 'scalar_base.yml')
    merge_config_path = File.join(config_dir, 'merge_test.yml')

    File.write(base_config_path, <<~YAML)
      AllValidators:
        FailOnSeverity: warning
    YAML

    File.write(merge_config_path, <<~YAML)
      inherit_from: scalar_base.yml
      AllValidators:
        FailOnSeverity: error
    YAML

    loader = Yard::Lint::ConfigLoader.new(merge_config_path)
    config = loader.load

    assert_equal('error', config['AllValidators']['FailOnSeverity'])

    FileUtils.rm_f([base_config_path, merge_config_path])
  end
end


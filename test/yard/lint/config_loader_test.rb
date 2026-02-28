# frozen_string_literal: true

require 'test_helper'

class YardLintConfigLoaderTest < Minitest::Test
  attr_reader :config_dir, :config_path

  def setup
    @config_dir = File.expand_path('../../../fixtures', __dir__)
    @config_path = File.join(config_dir, 'test_config.yml')
    FileUtils.mkdir_p(config_dir)
  end

  def teardown
    FileUtils.rm_f(config_path)
  end

  # .load (class method)

  def test_load_loads_a_configuration_file
    config_path_local = File.join(config_dir, 'basic_config.yml')
    File.write(config_path_local, "AllValidators:\n  Exclude:\n    - 'vendor/**/*'")

    config = Yard::Lint::ConfigLoader.load(config_path_local)

    assert_kind_of(Hash, config)
    assert_equal(['vendor/**/*'], config['AllValidators']['Exclude'])

    File.delete(config_path_local)
  end

  # .validator_module

  def test_validator_module_returns_the_correct_module_for_tags_order
    assert_equal(Yard::Lint::Validators::Tags::Order, Yard::Lint::ConfigLoader.validator_module('Tags/Order'))
  end

  def test_validator_module_returns_the_correct_module_for_tags_invalidtypes
    assert_equal(Yard::Lint::Validators::Tags::InvalidTypes, Yard::Lint::ConfigLoader.validator_module('Tags/InvalidTypes'))
  end

  def test_validator_module_returns_the_correct_module_for_tags_apitags
    assert_equal(Yard::Lint::Validators::Tags::ApiTags, Yard::Lint::ConfigLoader.validator_module('Tags/ApiTags'))
  end

  def test_validator_module_returns_the_correct_module_for_documentation_undocumentedmethodarguments
    assert_equal(
      Yard::Lint::Validators::Documentation::UndocumentedMethodArguments,
      Yard::Lint::ConfigLoader.validator_module('Documentation/UndocumentedMethodArguments')
    )
  end

  def test_validator_module_returns_the_correct_module_for_semantic_abstractmethods
    assert_equal(
      Yard::Lint::Validators::Semantic::AbstractMethods,
      Yard::Lint::ConfigLoader.validator_module('Semantic/AbstractMethods')
    )
  end

  def test_validator_module_returns_the_correct_module_for_warnings_unknowntag
    assert_equal(
      Yard::Lint::Validators::Warnings::UnknownTag,
      Yard::Lint::ConfigLoader.validator_module('Warnings/UnknownTag')
    )
  end

  def test_validator_module_returns_the_correct_module_for_documentation_undocumentedobjects
    assert_equal(
      Yard::Lint::Validators::Documentation::UndocumentedObjects,
      Yard::Lint::ConfigLoader.validator_module('Documentation/UndocumentedObjects')
    )
  end

  def test_validator_module_returns_nil_for_non_existent_validators
    assert_nil(Yard::Lint::ConfigLoader.validator_module('Tags/NonExistent'))
  end

  # #load (instance method)

  def test_load_loads_a_simple_configuration
    File.write(config_path, <<~YAML)
      AllValidators:
        Exclude:
          - 'test/**/*'
    YAML

    loader = Yard::Lint::ConfigLoader.new(config_path)
    config = loader.load

    assert_equal(['test/**/*'], config['AllValidators']['Exclude'])
  end

  def test_load_handles_empty_configuration_files
    File.write(config_path, '')

    loader = Yard::Lint::ConfigLoader.new(config_path)
    config = loader.load

    assert_equal({}, config)
  end

  def test_load_merges_inherited_configurations_with_inherit_from
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

  def test_load_handles_multiple_inherited_files_with_inherit_from
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

  def test_load_raises_error_on_circular_dependencies
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

  def test_load_overrides_inherited_array_values_completely
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

  def test_load_merges_hash_values_deeply
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

  def test_load_skips_non_existent_inherited_files
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

  def test_gem_inheritance_handles_missing_gems_gracefully
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

  def test_merge_behavior_does_not_include_inherit_from_in_merged_config
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

  def test_merge_behavior_does_not_include_inherit_gem_in_merged_config
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

  def test_merge_behavior_merges_scalar_values_by_overriding
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

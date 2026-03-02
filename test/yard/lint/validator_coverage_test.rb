# frozen_string_literal: true

describe 'Yard::Lint::ValidatorCoverage' do
  attr_reader :all_validators, :project_root

  before do
    @all_validators = Yard::Lint::ConfigLoader::ALL_VALIDATORS
    @project_root = File.expand_path('../../../', __dir__)
  end

  it 'yard lint yml includes all discovered validators' do
    config_content = File.read(File.join(@project_root, '.yard-lint.yml'))

    @all_validators.each do |validator_name|
      assert_includes(config_content, "#{validator_name}:",
                      "Missing validator #{validator_name} in .yard-lint.yml")
    end
  end

  it 'default config yml template includes all discovered validators' do
    template_path = File.join(@project_root, 'lib/yard/lint/templates/default_config.yml')
    template_content = File.read(template_path)

    @all_validators.each do |validator_name|
      assert_includes(template_content, "#{validator_name}:",
                      "Missing validator #{validator_name} in default_config.yml")
    end
  end

  it 'strict config yml template includes all discovered validators' do
    template_path = File.join(@project_root, 'lib/yard/lint/templates/strict_config.yml')
    template_content = File.read(template_path)

    @all_validators.each do |validator_name|
      assert_includes(template_content, "#{validator_name}:",
                      "Missing validator #{validator_name} in strict_config.yml")
    end
  end
end


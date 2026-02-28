# frozen_string_literal: true

require 'test_helper'

class ValidatorDocumentationCoverageTest < Minitest::Test
  attr_reader :all_validators, :project_root

  def setup
    @all_validators = Yard::Lint::ConfigLoader::ALL_VALIDATORS
    @project_root = File.expand_path('../../../', __dir__)
  end

  def test_yard_lint_yml_includes_all_discovered_validators
    config_content = File.read(File.join(@project_root, '.yard-lint.yml'))

    @all_validators.each do |validator_name|
      assert_includes(config_content, "#{validator_name}:",
                      "Missing validator #{validator_name} in .yard-lint.yml")
    end
  end

  def test_default_config_yml_template_includes_all_discovered_validators
    template_path = File.join(@project_root, 'lib/yard/lint/templates/default_config.yml')
    template_content = File.read(template_path)

    @all_validators.each do |validator_name|
      assert_includes(template_content, "#{validator_name}:",
                      "Missing validator #{validator_name} in default_config.yml")
    end
  end

  def test_strict_config_yml_template_includes_all_discovered_validators
    template_path = File.join(@project_root, 'lib/yard/lint/templates/strict_config.yml')
    template_content = File.read(template_path)

    @all_validators.each do |validator_name|
      assert_includes(template_content, "#{validator_name}:",
                      "Missing validator #{validator_name} in strict_config.yml")
    end
  end
end

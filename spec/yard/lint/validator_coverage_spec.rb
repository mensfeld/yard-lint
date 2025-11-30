# frozen_string_literal: true

RSpec.describe 'Validator Documentation Coverage' do
  let(:all_validators) { Yard::Lint::ConfigLoader::ALL_VALIDATORS }

  describe '.yard-lint.yml' do
    let(:config_content) { File.read('.yard-lint.yml') }

    it 'includes all discovered validators' do
      all_validators.each do |validator_name|
        expect(config_content).to include("#{validator_name}:"),
          "Missing validator #{validator_name} in .yard-lint.yml"
      end
    end
  end

  describe 'default_config.yml template' do
    let(:template_path) { 'lib/yard/lint/templates/default_config.yml' }
    let(:template_content) { File.read(template_path) }

    it 'includes all discovered validators' do
      all_validators.each do |validator_name|
        expect(template_content).to include("#{validator_name}:"),
          "Missing validator #{validator_name} in default_config.yml"
      end
    end
  end

  describe 'strict_config.yml template' do
    let(:template_path) { 'lib/yard/lint/templates/strict_config.yml' }
    let(:template_content) { File.read(template_path) }

    it 'includes all discovered validators' do
      all_validators.each do |validator_name|
        expect(template_content).to include("#{validator_name}:"),
          "Missing validator #{validator_name} in strict_config.yml"
      end
    end
  end
end

# frozen_string_literal: true

# Proves that the shipped config templates agree with the validators' code
# defaults. Validator-config arrays/hashes are replaced (not merged) when a
# config file defines them, so a project that materialized a template via
# --init silently behaves differently from one with no config at all - e.g.
# the default template dropped yieldparam/raise from several ValidatedTags
# lists and the IMPORTANT pattern from Tags/InformalNotation.
describe 'Template defaults parity' do
  # Keys whose values templates may always set differently from code defaults
  GENERAL_EXEMPT_KEYS = %w[
    Enabled Severity Description StyleGuide VersionAdded VersionChanged
  ].freeze

  # Intentional template deviations from code defaults:
  # - ExcludedMethods: both templates additionally recommend skipping
  #   underscore-prefixed (private-convention) methods
  # - OrphanedSeverity: the strict template intentionally raises severity
  INTENTIONAL_DEVIATIONS = {
    'default_config.yml' => { 'Documentation/UndocumentedObjects' => %w[ExcludedMethods] },
    'strict_config.yml' => {
      'Documentation/UndocumentedObjects' => %w[ExcludedMethods],
      'Documentation/BlankLineBeforeDefinition' => %w[OrphanedSeverity],
      # The strict preset opts into strict constant-name checking
      'Tags/InvalidTypes' => %w[StrictConstantNames],
      # The strict preset opts into name-based @param matching
      'Documentation/UndocumentedMethodArguments' => %w[CheckParameterNames]
    }
  }.freeze

  %w[default_config.yml strict_config.yml].each do |template_name|
    it "#{template_name} matches the validators' code defaults" do
      template_path = File.expand_path(
        "../../lib/yard/lint/templates/#{template_name}", __dir__
      )
      template = YAML.load_file(template_path)
      mismatches = []

      template.each do |validator_name, template_cfg|
        next unless validator_name.include?('/') && template_cfg.is_a?(Hash)

        defaults = Yard::Lint::ConfigLoader.validator_config(validator_name)&.defaults
        next unless defaults

        exempt = GENERAL_EXEMPT_KEYS +
                 (INTENTIONAL_DEVIATIONS.dig(template_name, validator_name) || [])

        template_cfg.each do |key, value|
          next if exempt.include?(key)
          next unless defaults.key?(key)
          next if defaults[key] == value

          mismatches << "#{validator_name}.#{key}: " \
                        "template=#{value.inspect} defaults=#{defaults[key].inspect}"
        end
      end

      assert_empty(
        mismatches,
        "Template #{template_name} drifted from code defaults:\n#{mismatches.join("\n")}"
      )
    end
  end
end

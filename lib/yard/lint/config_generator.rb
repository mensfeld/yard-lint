# frozen_string_literal: true

module Yard
  module Lint
    # Generates default .yard-lint.yml configuration file
    class ConfigGenerator
      # Path to templates directory
      TEMPLATES_DIR = File.expand_path('templates', __dir__)

      # Generate .yard-lint.yml file in current directory
      # @param force [Boolean] overwrite existing file if true
      # @param strict [Boolean] generate strict configuration (all errors, 100% coverage)
      # @return [Boolean] true if file was created, false if already exists
      def self.generate(force: false, strict: false)
        config_path = File.join(Dir.pwd, Config::DEFAULT_CONFIG_FILE)

        if File.exist?(config_path) && !force
          false
        else
          template_name = strict ? 'strict_config.yml' : 'default_config.yml'
          template_path = File.join(TEMPLATES_DIR, template_name)
          content = File.read(template_path)
          File.write(config_path, content)
          true
        end
      end
    end
  end
end

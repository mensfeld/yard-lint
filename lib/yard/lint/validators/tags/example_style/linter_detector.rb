# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module ExampleStyle
          # Detects available linters (RuboCop or StandardRB) in the project
          class LinterDetector
            class << self
              # Detect which linter to use based on configuration and project setup
              # @param config_linter [String] configured linter preference ('auto', 'rubocop', 'standard', 'none')
              # @param project_root [String] project root directory for file checks
              # @return [Symbol] detected linter (:rubocop, :standard, or :none)
              def detect(config_linter, project_root: Dir.pwd)
                return :none if config_linter == 'none'
                return :rubocop if config_linter == 'rubocop' && rubocop_available?
                return :standard if config_linter == 'standard' && standard_available?

                # Auto-detection logic
                return :none unless config_linter == 'auto'

                # Priority 1: Check for .standard.yml config file
                return :standard if File.exist?(File.join(project_root, '.standard.yml')) && standard_available?

                # Priority 2: Check for .rubocop.yml config file
                return :rubocop if File.exist?(File.join(project_root, '.rubocop.yml')) && rubocop_available?

                # Priority 3: Check Gemfile for 'standard' gem
                gemfile_path = File.join(project_root, 'Gemfile')
                if File.exist?(gemfile_path)
                  gemfile_content = File.read(gemfile_path)
                  return :standard if gemfile_content.match?(/gem\s+['"]standard['"]/) && standard_available?
                  return :rubocop if gemfile_content.match?(/gem\s+['"]rubocop['"]/) && rubocop_available?
                end

                # Priority 4: Check for Gemfile.lock
                gemfile_lock_path = File.join(project_root, 'Gemfile.lock')
                if File.exist?(gemfile_lock_path)
                  lock_content = File.read(gemfile_lock_path)
                  return :standard if lock_content.include?('standard (') && standard_available?
                  return :rubocop if lock_content.include?('rubocop (') && rubocop_available?
                end

                :none
              end

              # Check if RuboCop gem is available
              # @return [Boolean] true if RuboCop can be loaded
              def rubocop_available?
                require 'rubocop'
                true
              rescue LoadError
                false
              end

              # Check if StandardRB gem is available
              # @return [Boolean] true if StandardRB can be loaded
              def standard_available?
                require 'standard'
                true
              rescue LoadError
                false
              end
            end
          end
        end
      end
    end
  end
end

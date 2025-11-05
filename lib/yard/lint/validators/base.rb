# frozen_string_literal: true

module Yard
  module Lint
    # Validators for checking different aspects of YARD documentation
    module Validators
      # Base YARD validator class
      class Base
        # Class-level cache shared across ALL validator classes
        # Must be stored on Base itself, not on subclasses
        @shared_command_cache = nil

        # Default yard stats options that we need to use
        DEFAULT_OPTIONS = [
          '--charset utf-8',
          '--markup markdown',
          '--no-progress'
        ].freeze

        # String with a temp dir to store the yard stats database
        # @note We run yard multiple times and in order not to rebuild db over and over
        #   again but reuse the same one, we have a single tmp dir for it
        YARDOC_TEMP_DIR = Dir.mktmpdir.freeze

        private_constant :YARDOC_TEMP_DIR

        attr_reader :config, :selection

        class << self
          # Unique identifier for this validator
          # @return [Symbol] validator identifier
          attr_accessor :id

          # Default configuration for this validator
          # @return [Hash] default configuration hash
          attr_accessor :defaults

          # Validators to combine with this one
          # @return [Array<String>] validator names to combine, empty array if standalone
          def combines_with
            @combines_with ||= []
          end

          # Set validators to combine with
          attr_writer :combines_with

          # Lazy-initialized command cache shared across all validator instances
          # This allows different validators to reuse results from identical YARD commands
          # @return [CommandCache] the command cache instance
          def command_cache
            # Use Base's cache, not subclass's cache
            Base.instance_variable_get(:@shared_command_cache) ||
              Base.instance_variable_set(:@shared_command_cache, CommandCache.new)
          end

          # Reset the command cache (primarily for testing)
          # @return [void]
          def reset_command_cache!
            Base.instance_variable_set(:@shared_command_cache, nil)
          end

          # Clear the YARD database (primarily for testing)
          # @return [void]
          def clear_yard_database!
            return unless defined?(YARDOC_TEMP_DIR)

            FileUtils.rm_rf(Dir.glob(File.join(YARDOC_TEMP_DIR, '*')))
          end
        end

        # @param config [Yard::Lint::Config] configuration object
        # @param selection [Array<String>] array with ruby files we want to check
        def initialize(config, selection)
          @config = config
          @selection = selection
        end

        # Performs the validation and returns raw results
        # @return [Hash] hash with stdout, stderr and exit_code keys
        def call
          # There might be a case when there were no files because someone ignored all
          # then we need to return empty result
          return raw if selection.nil? || selection.empty?

          # Anything that goes to shell needs to be escaped
          escaped_file_names = escape(selection).join(' ')

          yard_cmd(YARDOC_TEMP_DIR, escaped_file_names)
        end

        private

        # @return [String] all arguments with which yard stats should be executed
        def shell_arguments
          args = escape(config.options).join(' ')
          "#{args} #{DEFAULT_OPTIONS.join(' ')}"
        end

        # @param array [Array] escape all elements in an array
        # @return [Array] array with escaped elements
        def escape(array)
          array.map { |cmd| Shellwords.escape(cmd) }
        end

        # Builds a raw hash that can be used for further processing
        # @param stdout [String, Hash, Array] anything that we want to return as stdout
        # @param stderr [String, Hash, Array] any errors that occurred
        # @param exit_code [Integer, false] result exit code or false if we want to decide it based
        #   on the stderr content
        # @return [Hash] hash with stdout, stderr and exit_code keys
        def raw(stdout = '', stderr = '', exit_code = false)
          {
            stdout: stdout,
            stderr: stderr,
            exit_code: exit_code || (stderr.empty? ? 0 : 1)
          }
        end

        # Executes a shell command and returns the result
        # Routes through command cache to avoid duplicate executions
        # @param cmd [String] shell command to execute
        # @return [Hash] hash with stdout, stderr and exit_code keys
        def shell(cmd)
          self.class.command_cache.execute(cmd)
        end
      end
    end
  end
end

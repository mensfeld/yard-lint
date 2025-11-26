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

        # Class-level settings for in-process execution
        # These must be set on each subclass, not on Base
        @in_process_enabled = nil
        @in_process_visibility = nil

        # Default YARD command options that we need to use
        DEFAULT_OPTIONS = [
          '--charset utf-8',
          '--markup markdown',
          '--no-progress'
        ].freeze

        # Base temp directory for YARD databases
        # Each unique set of arguments gets its own subdirectory to prevent contamination
        YARDOC_BASE_TEMP_DIR = Dir.mktmpdir.freeze

        private_constant :YARDOC_BASE_TEMP_DIR

        attr_reader :config, :selection

        class << self
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

          # Clear all YARD databases (primarily for testing)
          # @return [void]
          def clear_yard_database!
            return unless defined?(YARDOC_BASE_TEMP_DIR)

            FileUtils.rm_rf(Dir.glob(File.join(YARDOC_BASE_TEMP_DIR, '*')))
          end

          # Declare that this validator supports in-process execution
          # @param visibility [Symbol] visibility filter for objects (:public or :all)
          #   :public - only include public methods (default, no --private/--protected)
          #   :all - include all methods (equivalent to --private --protected)
          # @return [void]
          # @example
          #   class Validator < Base
          #     in_process visibility: :all
          #   end
          def in_process(visibility: :public)
            @in_process_enabled = true
            @in_process_visibility = visibility
          end

          # Check if this validator supports in-process execution
          # @return [Boolean]
          def in_process?
            @in_process_enabled == true
          end

          # Get the visibility setting for in-process execution
          # @return [Symbol, nil] :public, :all, or nil if not set
          def in_process_visibility
            @in_process_visibility
          end

          # Get the validator name from the class namespace
          # @return [String, nil] validator name like 'Tags/Order' or nil
          # @example
          #   Yard::Lint::Validators::Tags::Order::Validator.validator_name
          #   # => 'Tags/Order'
          def validator_name
            name&.split('::')&.then do |parts|
              idx = parts.index('Validators')
              return nil unless idx && parts[idx + 1] && parts[idx + 2]

              "#{parts[idx + 1]}/#{parts[idx + 2]}"
            end
          end
        end

        # @param config [Yard::Lint::Config] configuration object
        # @param selection [Array<String>] array with ruby files we want to check
        def initialize(config, selection)
          @config = config
          @selection = selection
        end

        # Execute query for a single object during in-process execution.
        # Override this method in validators that support in-process execution.
        # @param object [YARD::CodeObjects::Base] the code object to query
        # @param collector [Executor::ResultCollector] collector for output
        # @return [void]
        # @example
        #   def in_process_query(object, collector)
        #     return unless object.docstring.all.empty?
        #     collector.puts "#{object.file}:#{object.line}: #{object.title}"
        #   end
        def in_process_query(object, collector)
          raise NotImplementedError, "#{self.class} must implement in_process_query for in-process execution"
        end

        # Performs the validation and returns raw results
        # @return [Hash] hash with stdout, stderr and exit_code keys
        def call
          # There might be a case when there were no files because someone ignored all
          # then we need to return empty result
          return raw if selection.nil? || selection.empty?

          # Anything that goes to shell needs to be escaped
          escaped_file_names = escape(selection)

          # Use a unique YARD database per set of arguments to prevent contamination
          # between validators with different file selections or options
          yardoc_dir = yardoc_temp_dir_for_arguments(escaped_file_names.join(' '))

          # For large file lists, use a temporary file to avoid ARG_MAX limits
          # Write file paths to temp file, one per line
          Tempfile.create(['yard_files', '.txt']) do |f|
            escaped_file_names.each { |file| f.puts(file) }
            f.flush

            yard_cmd(yardoc_dir, f.path)
          end
        end

        private

        # Returns a unique YARD database directory for the given arguments
        # Uses SHA256 hash of the normalized arguments to ensure different file sets
        # get separate databases, preventing contamination
        # @param escaped_file_names [String] escaped file names to process
        # @return [String] path to the YARD database directory
        def yardoc_temp_dir_for_arguments(escaped_file_names)
          # Combine all arguments that affect YARD output
          all_args = "#{shell_arguments} #{escaped_file_names}"

          # Create a hash of the arguments for a unique directory name
          args_hash = Digest::SHA256.hexdigest(all_args)

          # Create subdirectory under base temp dir
          dir = File.join(YARDOC_BASE_TEMP_DIR, args_hash)
          FileUtils.mkdir_p(dir) unless File.directory?(dir)

          dir
        end

        # @return [String] all arguments with which YARD command should be executed
        def shell_arguments
          validator_name = self.class.name&.split('::')&.then do |parts|
            idx = parts.index('Validators')
            next config.options unless idx && parts[idx + 1] && parts[idx + 2]

            "#{parts[idx + 1]}/#{parts[idx + 2]}"
          end || config.options

          yard_options = config.validator_yard_options(validator_name)
          args = escape(yard_options).join(' ')
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

        # Retrieves configuration value with fallback to default
        # Automatically determines the validator name from the class namespace
        #
        # @param key [String] the configuration key to retrieve
        # @return [Object] the configured value or default value from the validator's Config.defaults
        # @note The validator name is automatically extracted from the class namespace.
        #   For example, Yard::Lint::Validators::Tags::RedundantParamDescription::Validator
        #   becomes 'Tags/RedundantParamDescription'
        # @example Usage in a validator (e.g., Tags::RedundantParamDescription)
        #   def config_articles
        #     config_or_default('Articles')
        #   end
        def config_or_default(key)
          validator_name = self.class.name&.split('::')&.then do |parts|
            idx = parts.index('Validators')
            next nil unless idx && parts[idx + 1] && parts[idx + 2]

            "#{parts[idx + 1]}/#{parts[idx + 2]}"
          end

          # Get the validator module's Config class
          validator_config_class = begin
            # Get parent module (e.g., Yard::Lint::Validators::Tags::RedundantParamDescription)
            parent_module = self.class.name.split('::')[0..-2].join('::')
            Object.const_get("#{parent_module}::Config")
          rescue NameError
            nil
          end

          defaults = validator_config_class&.defaults || {}

          return defaults[key] unless validator_name

          config.validator_config(validator_name, key) || defaults[key]
        end
      end
    end
  end
end

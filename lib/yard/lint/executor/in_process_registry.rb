# frozen_string_literal: true

require 'yard'

module Yard
  module Lint
    # In-process execution components for YARD validation.
    # Provides registry management, query execution, and result collection
    # for running validators within the same Ruby process.
    module Executor
      # Manages shared YARD::Registry for in-process execution.
      # Ensures files are parsed once and shared across all validators.
      class InProcessRegistry
        # @return [Array<String>] warnings captured during parsing
        attr_reader :warnings

        def initialize
          @parsed = false
          @warnings = []
          @mutex = Mutex.new
        end

        # Parse Ruby source files and populate the YARD registry.
        # Captures any warnings emitted by YARD during parsing for later dispatch.
        # @param files [Array<String>] absolute or relative paths to Ruby source files
        # @return [void]
        def parse(files)
          @mutex.synchronize do
            return if @parsed

            YARD::Registry.clear

            # Suppress YARD's default output by setting log level high
            # YARD uses its own logging levels, 4 is ERROR/FATAL level
            original_level = YARD::Logger.instance.level
            YARD::Logger.instance.level = 4 # Only show fatal errors

            @warnings = capture_warnings { YARD.parse(files) }
            @parsed = true

            YARD::Logger.instance.level = original_level
          end
        end

        # Check if registry has been parsed
        # @return [Boolean]
        def parsed?
          @parsed
        end

        # Get all objects from the registry
        # @return [Array<YARD::CodeObjects::Base>]
        def all_objects
          YARD::Registry.all
        end

        # Get objects filtered for a specific validator
        # @param visibility [Symbol] visibility filter, either :all or :public
        # @param file_excludes [Array<String>] glob patterns for files to exclude
        # @param file_selection [Array<String>, nil] specific files to include (nil = all files)
        # @return [Array<YARD::CodeObjects::Base>]
        def objects_for_validator(visibility:, file_excludes: [], file_selection: nil)
          objects = all_objects

          # Filter by visibility
          unless visibility == :all
            objects = objects.select do |obj|
              !obj.respond_to?(:visibility) || obj.visibility == :public
            end
          end

          # Filter by file selection (if provided)
          if file_selection && !file_selection.empty?
            expanded_selection = file_selection.to_set { |f| File.expand_path(f) }
            objects = objects.select do |obj|
              obj.file && expanded_selection.include?(File.expand_path(obj.file))
            end
          end

          # Filter by file excludes
          unless file_excludes.empty?
            objects = objects.reject do |obj|
              next false unless obj.file

              file_excludes.any? do |pattern|
                File.fnmatch(pattern, obj.file, File::FNM_PATHNAME | File::FNM_EXTGLOB)
              end
            end
          end

          objects
        end

        # Clear the registry and reset state
        # @return [void]
        def clear!
          @mutex.synchronize do
            YARD::Registry.clear
            @parsed = false
            @warnings = []
          end
        end

        private

        # Capture warnings during a block execution
        # @yield Block to execute while capturing warnings
        # @return [Array<String>] captured warnings
        def capture_warnings
          captured = []

          # Store original warn method
          original_warn = YARD::Logger.instance.method(:warn)

          # Override warn to capture warnings
          YARD::Logger.instance.define_singleton_method(:warn) do |*args|
            message = args.first.to_s
            captured << message
            original_warn.call(*args)
          end

          yield

          captured
        ensure
          # Restore original warn method
          YARD::Logger.instance.define_singleton_method(:warn, original_warn) if original_warn
        end
      end
    end
  end
end

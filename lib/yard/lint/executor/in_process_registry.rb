# frozen_string_literal: true

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
        # @param source [String, nil] in-memory source; when given, `files.first` is used
        #   as the virtual filename for registry/location reporting only
        # @return [void]
        def parse(files, source: nil)
          @mutex.synchronize do
            return if @parsed

            YARD::Registry.clear

            # Suppress YARD's default output by setting log level high
            # YARD uses its own logging levels, 4 is ERROR/FATAL level
            original_level = YARD::Logger.instance.level
            YARD::Logger.instance.level = 4 # Only show fatal errors

            if source
              virtual_path = files.first
              # First pass: register directive/macro definitions from the in-memory source.
              # We set parser.file manually so registered objects carry the virtual path.
              parse_source_string(source, virtual_path)
              # Clear checksums so the second pass is not skipped
              YARD::Registry.checksums.clear
              # Second pass: full parse with all directives available
              @warnings = capture_warnings { parse_source_string(source, virtual_path) }
            else
              # First pass: parse all files to process directive definitions
              YARD.parse(files)

              # Clear checksums to force reparsing without clearing the registry.
              # This allows macro definitions from the first pass to be available
              # during the second pass, enabling proper directive expansion regardless of parse order.
              YARD::Registry.checksums.clear

              # Second pass: reparse files now that all directive definitions are available
              @warnings = capture_warnings { YARD.parse(files) }
            end

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

        # Parse Ruby source from a string and register objects under a virtual path.
        # YARD::Parser::SourceParser#parse accepts a StringIO but keeps @file as '(stdin)'
        # unless we set it explicitly before parsing.
        # @param source [String] Ruby source code to parse
        # @param virtual_path [String] filename to assign to registered objects
        # @return [void]
        def parse_source_string(source, virtual_path)
          parser = YARD::Parser::SourceParser.new(:ruby)
          parser.file = virtual_path
          parser.parse(StringIO.new(source))
        end

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
          sc = YARD::Logger.instance.singleton_class
          sc.remove_method(:warn) if sc.public_instance_methods(false).include?(:warn)
        end
      end
    end
  end
end

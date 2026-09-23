# frozen_string_literal: true

module Yard
  module Lint
    # Renders a human-readable explanation of a single validator for the terminal.
    #
    # The explanation is sourced from the validator's own YARD documentation block
    # (the module file, e.g. `validators/tags/type_syntax.rb`) - yard-lint reads its
    # own YARD docs to explain itself. This keeps the explanation next to the code it
    # documents rather than in a separate file that can drift, and gives the doc
    # blocks a standing reason to stay accurate.
    #
    # @example
    #   puts Yard::Lint::Explainer.call("Tags/TypeSyntax")
    class Explainer
      # Keys in a validator's defaults that are surfaced in the header rather than
      # listed as tunable configuration options.
      META_KEYS = %w[Enabled Severity].freeze

      # Build the explanation for a validator.
      # @param name [String] validator name (e.g. 'Tags/TypeSyntax')
      # @return [String] formatted, terminal-ready explanation
      def self.call(name)
        new(name).call
      end

      # @param name [String] validator name (e.g. 'Tags/TypeSyntax')
      def initialize(name)
        @name = name
      end

      # @return [String] formatted, terminal-ready explanation
      # @raise [ArgumentError] if name is not a known validator
      def call
        unless ConfigLoader::ALL_VALIDATORS.include?(@name)
          raise ArgumentError, "Unknown validator: #{@name.inspect}"
        end

        [header, body].compact.join("\n")
      end

      private

      # @return [String] the metadata header (name, defaults) for the validator
      def header
        lines = [@name.to_s]
        lines << "  Enabled by default: #{default_config.validator_enabled?(@name)}"
        lines << "  Default severity:   #{default_config.validator_severity(@name)}"

        config_keys = validator_defaults.keys - META_KEYS
        lines << "  Configuration keys: #{config_keys.join(', ')}" if config_keys.any?
        lines.join("\n")
      end

      # @return [String] the documentation body (description, config, examples)
      def body
        doc = documentation
        return raw_comment_fallback if doc.nil?

        sections = ["\n#{doc[:description]}"]
        sections << render_examples(doc[:examples]) if doc[:examples].any?
        sections.join("\n")
      end

      # @param examples [Array(String, String)] pairs of example label and code
      # @return [String] the rendered "Examples:" section
      def render_examples(examples)
        rendered = examples.map do |name, text|
          code = text.each_line.map { |line| "    #{line}" }.join
          "  #{name}\n#{code}".rstrip
        end
        "\nExamples:\n#{rendered.join("\n\n")}"
      end

      # A config carrying only built-in defaults (no user overrides), used as the
      # authoritative source for the validator's default enabled state and
      # severity so the header never drifts from how the linter actually resolves
      # them (see Config#validator_enabled? / #validator_severity).
      # @return [Config] the defaults-only config
      def default_config
        @default_config ||= Config.new
      end

      # @return [Hash] the validator's default configuration
      def validator_defaults
        config = ConfigLoader.validator_config(@name)
        config&.defaults || {}
      end

      # Parse the validator's module file with YARD and extract its description
      # and examples. Runs in an isolated registry - any objects a caller parsed
      # before us are saved and restored - so explaining a validator never
      # clobbers the shared YARD::Registry.
      # @return [Hash, nil] { description: String, examples: Array((String, String)) }
      #   or nil if no docstring is available
      def documentation
        path = source_path
        return nil unless path && File.exist?(path)

        saved = YARD::Registry.all
        YARD::Registry.clear
        begin
          YARD.parse_string(File.read(path))
          docstring = YARD::Registry.at(object_path)&.docstring
          return nil if docstring.nil? || docstring.to_s.strip.empty?

          {
            description: docstring.to_s,
            examples: docstring.tags(:example).map { |tag| [tag.name, tag.text.to_s] }
          }
        ensure
          YARD::Registry.clear
          saved.each { |object| YARD::Registry.register(object) }
        end
      end

      # @return [String] the fully-qualified code object path (e.g.
      #   'Yard::Lint::Validators::Tags::TypeSyntax')
      def object_path
        category, validator = @name.split('/')
        "Yard::Lint::Validators::#{category}::#{validator}"
      end

      # Resolve the validator module file from its name by inverting the casing
      # convention used in ConfigLoader.discover_validators.
      # @return [String] absolute path to the validator module file
      def source_path
        category, validator = @name.split('/')
        File.join(__dir__, 'validators', snake_case(category), "#{snake_case(validator)}.rb")
      end

      # Convert a PascalCase segment to snake_case (inverse of the
      # `split('_').map(&:capitalize).join` used during discovery).
      # @param string [String] PascalCase name (e.g. 'TypeSyntax')
      # @return [String] snake_case name (e.g. 'type_syntax')
      def snake_case(string)
        string.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
      end

      # Defensive fallback: print the raw leading comment block from the module
      # file when YARD yields no docstring. Every validator currently ships a doc
      # block, so this should not normally be reached.
      # @return [String, nil] the raw comment text, or nil if it cannot be read
      def raw_comment_fallback
        path = source_path
        return nil unless path && File.exist?(path)

        comment = []
        File.foreach(path) do |line|
          stripped = line.strip
          if stripped.start_with?('#')
            comment << stripped.sub(/\A#\s?/, '')
          elsif stripped.start_with?('module ') && comment.any?
            break
          else
            comment.clear
          end
        end
        comment.any? ? "\n#{comment.join("\n")}" : nil
      end
    end
  end
end

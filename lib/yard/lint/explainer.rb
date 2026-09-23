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
    #   puts Yard::Lint::Explainer.call('Tags/TypeSyntax')
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
      def call
        [header, body].compact.join("\n")
      end

      private

      # @return [String] the metadata header (name, defaults) for the validator
      def header
        defaults = validator_defaults
        lines = [@name.to_s]
        lines << "  Enabled by default: #{defaults.fetch('Enabled', true)}"
        lines << "  Default severity:   #{defaults['Severity'] || '(department default)'}"

        config_keys = defaults.keys - META_KEYS
        lines << "  Configuration keys: #{config_keys.join(', ')}" if config_keys.any?
        lines.join("\n")
      end

      # @return [String] the documentation body (description, config, examples)
      def body
        docstring = validator_docstring
        return raw_comment_fallback if docstring.nil? || docstring.to_s.strip.empty?

        sections = ["\n#{docstring}"]

        examples = docstring.tags(:example)
        sections << render_examples(examples) if examples.any?
        sections.join("\n")
      end

      # @param examples [Array<YARD::Tags::Tag>] example tags from the docstring
      # @return [String] the rendered "Examples:" section
      def render_examples(examples)
        rendered = examples.map do |example|
          code = example.text.to_s.each_line.map { |line| "    #{line}" }.join
          "  #{example.name}\n#{code}".rstrip
        end
        "\nExamples:\n#{rendered.join("\n\n")}"
      end

      # @return [Hash] the validator's default configuration
      def validator_defaults
        config = ConfigLoader.validator_config(@name)
        config&.defaults || {}
      end

      # Parse the validator's module file with YARD and return its docstring.
      # @return [YARD::Docstring, nil] the module docstring, or nil if unavailable
      def validator_docstring
        path = source_path
        return nil unless path && File.exist?(path)

        YARD::Registry.clear
        YARD.parse_string(File.read(path))
        object = YARD::Registry.at(object_path)
        object&.docstring
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

# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        # TextSubstitution validator
        #
        # Detects forbidden characters or strings in YARD documentation comments
        # and suggests replacements. The primary use case is detecting AI-generated
        # em-dashes (—, U+2014) and en-dashes (–, U+2013) where a plain hyphen (-)
        # is preferred, but any string-to-string substitution rule can be configured.
        #
        # All substitution rules are checked on every line — multiple violations can
        # be reported for the same line when more than one forbidden string appears.
        # Fenced code blocks (``` ... ```) are skipped.
        #
        # Disabled by default — enable it and configure Substitutions to taste.
        #
        # @example Bad - em-dash used in documentation
        #   # Connects the start — and end of the range.
        #   def connect(start, finish)
        #   end
        #
        # @example Good - plain hyphen
        #   # Connects the start - and end of the range.
        #   def connect(start, finish)
        #   end
        #
        # ## Configuration
        #
        # Enable with built-in defaults (em-dash and en-dash):
        #
        #     Documentation/TextSubstitution:
        #       Enabled: true
        #
        # Enable with explicit substitution rules:
        #
        #     Documentation/TextSubstitution:
        #       Enabled: true
        #       Substitutions:
        #         "—": "-"    # em-dash (U+2014)
        #         "–": "-"    # en-dash (U+2013)
        #         "…": "..."  # ellipsis (U+2026)
        #
        # To disable:
        #
        #     Documentation/TextSubstitution:
        #       Enabled: false
        module TextSubstitution
        end
      end
    end
  end
end

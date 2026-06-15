# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        # UnderfilledLines validator
        #
        # The inverse of {LineLength}: instead of flagging documentation lines that are
        # too *long*, it flags documentation prose paragraphs that wrap **too early** -
        # text that uses only a fraction of the available width and spills onto extra
        # lines, wasting vertical space. This pattern is common in AI-generated docs.
        #
        # Only the free-text description body is checked. YARD tags (`@param`, `@return`,
        # `@example`, ...), fenced and indented code, lists, tables, headings,
        # blockquotes and non-ASCII text are left untouched. A paragraph is reported
        # only when *all* of these hold, so ambiguous cases are never flagged:
        #
        # * greedily re-wrapping its words at `MaxLength` would genuinely use fewer lines;
        # * the unused space on its widest line is at least `MinTrailingSpace` columns;
        # * it is not deliberately broken one sentence/clause per line (every non-final
        #   line ending at a `SentenceEndChars` boundary is treated as an intentional
        #   semantic line break and skipped).
        #
        # Disabled by default - this is a stylistic, opinionated check. Enable it to
        # tighten draft or AI-written documentation.
        #
        # @example Bad - prose wraps at ~55 columns when 120 are available
        #   # Processes the incoming payload and returns a normalized
        #   # hash that downstream consumers can rely on for routing.
        #   def process(payload)
        #   end
        #
        # @example Good - prose fills the available width before wrapping
        #   # Processes the incoming payload and returns a normalized hash that downstream
        #   # consumers can rely on for routing.
        #   def process(payload)
        #   end
        #
        # @example Good - semantic line breaks (one sentence per line) are never flagged
        #   # Validates the input.
        #   # Normalizes the casing.
        #   # Persists the record.
        #   def call
        #   end
        #
        # ## Configuration
        #
        # To enable with custom settings:
        #
        #     Documentation/UnderfilledLines:
        #       Enabled: true
        #       MaxLength: 120
        #       MinTrailingSpace: 20
        #
        # ## Reliability
        #
        # Unlike {LineLength} - which measures an objective property (characters over a
        # limit) - "this line should have been longer" is a stylistic judgement. The
        # validator is deliberately conservative and biased toward silence: it would
        # rather miss a case than emit a false positive. Projects that use semantic line
        # breaks (one sentence or clause per line, see https://sembr.org) should leave it
        # off, or add `,` to `SentenceEndChars`.
        #
        # To disable:
        #
        #     Documentation/UnderfilledLines:
        #       Enabled: false
        module UnderfilledLines
        end
      end
    end
  end
end

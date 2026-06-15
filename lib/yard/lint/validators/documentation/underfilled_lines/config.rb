# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module UnderfilledLines
          # Configuration for UnderfilledLines validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :underfilled_lines
            self.defaults = {
              'Enabled' => false,
              'Severity' => 'convention',
              # Target width. Re-wrapping prose at this width must save a line for an
              # offense to be reported. Mirror your Documentation/LineLength MaxLength.
              'MaxLength' => 120,
              # Only flag when the widest non-final line of the paragraph leaves at
              # least this many unused columns - avoids nitpicking near-full prose.
              'MinTrailingSpace' => 20,
              # Paragraphs shorter than this are never flagged (a single line cannot
              # be "under-filled" - there is nothing to pull up onto it).
              'MinParagraphLines' => 2,
              # A non-final prose line ending in one of these characters is treated as
              # a deliberate sentence/clause break, and its paragraph is left alone.
              # Add ',' to also respect comma breaks (suppresses more, catches less).
              'SentenceEndChars' => ['.', '?', '!', ':', ';'],
              # Skip paragraphs containing non-ASCII text: String#length is not a
              # reliable display width for CJK/full-width/emoji content.
              'SkipNonAscii' => true
            }.freeze
          end
        end
      end
    end
  end
end

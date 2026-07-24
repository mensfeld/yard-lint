# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        # LineLength validator
        #
        # Detects documentation comment lines that exceed a configured maximum length.
        # Only checks lines belonging to YARD docstring blocks (comment lines directly
        # above a documentable Ruby construct). YARD's parsed docstring is used to
        # determine which lines belong to a docstring, avoiding fragile backwards-scanning.
        #
        # Disabled by default - enable it and set MaxLength to taste.
        #
        # @example Bad - line exceeds MaxLength (120)
        #   # This documentation line is too long and exceeds the configured maximum length.
        #   def process(value)
        #   end
        #
        # @example Good - line within MaxLength
        #   # Process the given value.
        #   def process(value)
        #   end
        #
        # ## Configuration
        #
        # To enable with a custom limit:
        #
        #     Documentation/LineLength:
        #       Enabled: true
        #       MaxLength: 100
        #
        # To disable:
        #
        #     Documentation/LineLength:
        #       Enabled: false
        module LineLength
        end
      end
    end
  end
end

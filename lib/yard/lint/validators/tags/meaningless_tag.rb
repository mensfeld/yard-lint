# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        # MeaninglessTag validator module
        # Detects @param and @option tags on classes, modules, or constants
        # (these tags only make sense on methods)
        module MeaninglessTag
        end
      end
    end
  end
end

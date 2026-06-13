# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module InvalidTypes
          # Parser for invalid tags types output
          # Reuses location parsing logic from undocumented method arguments
          class Parser < Validators::Documentation::UndocumentedMethodArguments::Parser
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module InvalidTypes
          # Configuration for InvalidTypes validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :invalid_types
            self.defaults = {
              'Enabled' => true,
              'Severity' => 'warning',
              'ValidatedTags' => %w[param option return yieldreturn yieldparam raise],
              'ExtraTypes' => [],
              # Opt-in: when true, a CamelCase type name that is neither a loaded
              # Ruby constant nor resolvable in the analyzed codebase's YARD
              # registry is flagged (catches typos like `Strng`). Off by default
              # because YARD does not load the project, so types defined only in
              # un-analyzed dependencies would otherwise be reported.
              'StrictConstantNames' => false
            }.freeze
          end
        end
      end
    end
  end
end

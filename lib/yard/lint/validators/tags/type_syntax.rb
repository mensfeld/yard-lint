# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        # TypeSyntax validator
        #
        # Validates YARD type syntax using YARD's TypesExplainer::Parser. This
        # validator ensures that type annotations can be properly parsed by YARD
        # and follow YARD's type specification format. This validator is enabled
        # by default.
        #
        # @example Bad - Invalid type syntax that YARD cannot parse
        #   # @param data [{String, Integer}] invalid hash syntax
        #   # @return [String]] extra closing bracket
        #   def process(data)
        #   end
        #
        # @example Good - Valid parseable YARD type syntax
        #   # @param data [Hash{String => Integer}] valid hash syntax
        #   # @return [String] correct bracket usage
        #   def process(data)
        #   end
        #
        # @example Configuration - Disable this validator
        #   Tags/TypeSyntax:
        #     Enabled: false
        #
        module TypeSyntax
        end
      end
    end
  end
end

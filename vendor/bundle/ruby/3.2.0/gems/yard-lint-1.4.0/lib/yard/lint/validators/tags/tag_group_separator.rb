# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        # TagGroupSeparator validator
        #
        # Enforces blank line separators between different groups of YARD documentation
        # tags. This improves readability by visually grouping semantically related tags.
        # This validator is disabled by default.
        #
        # @example Bad - No separator between @param and @return
        #   # @param organization_id [String] the organization ID
        #   # @param id [String] the pet ID
        #   # @return [Pet] the pet object
        #   def call(organization_id, id)
        #   end
        #
        # @example Good - Blank line separates tag groups
        #   # @param organization_id [String] the organization ID
        #   # @param id [String] the pet ID
        #   #
        #   # @return [Pet] the pet object
        #   def call(organization_id, id)
        #   end
        #
        # ## Configuration
        #
        # To enable this validator:
        #
        #     Tags/TagGroupSeparator:
        #       Enabled: true
        #
        # To customize tag groups:
        #
        #     Tags/TagGroupSeparator:
        #       Enabled: true
        #       TagGroups:
        #         param: [param, option]
        #         return: [return]
        #         error: [raise]
        #         yield: [yield, yieldparam, yieldreturn]
        module TagGroupSeparator
        end
      end
    end
  end
end

# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        # TagSeparator validator
        #
        # Enforces a blank line between *every* pair of consecutive YARD tags,
        # including consecutive tags of the same type (e.g. two `@param` tags).
        # This is stricter than {TagGroupSeparator}, which only separates
        # different tag *groups* and therefore can never separate same-type tags
        # such as sibling `@param` tags. This validator is disabled by default.
        #
        # @example Bad - No blank line between consecutive @param tags
        #   # @param organization_id [String] the organization ID
        #   # @param id [String] the pet ID
        #   # @return [Pet] the pet object
        #   def call(organization_id, id)
        #   end
        #
        # @example Good - Blank line separates every tag
        #   # @param organization_id [String] the organization ID
        #   #
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
        #     Tags/TagSeparator:
        #       Enabled: true
        #
        # To allow certain tags to immediately follow the previous tag without a
        # blank line, list them under `Exempt`. This is useful for `@option`
        # tags, which document keys of a preceding `@param` hash and read best
        # when clustered directly beneath it:
        #
        #     Tags/TagSeparator:
        #       Enabled: true
        #       Exempt:
        #         - option
        #
        # With the configuration above, this is valid:
        #
        #     # @param opts [Hash] the options
        #     # @option opts [String] :name the name
        #     # @option opts [Integer] :age the age
        #     #
        #     # @return [void]
        #
        # To also require a blank line between the description and the first tag,
        # set `RequireAfterDescription`:
        #
        #     Tags/TagSeparator:
        #       Enabled: true
        #       RequireAfterDescription: true
        module TagSeparator
        end
      end
    end
  end
end

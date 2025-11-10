# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      # Tags validators - validate YARD tag quality and consistency
      module Tags
        # RedundantParamDescription validator
        #
        # Detects parameter descriptions that add no meaningful information beyond
        # what's already obvious from the parameter name and type. This validator
        # helps maintain high-quality documentation by flagging descriptions that
        # should either be expanded with meaningful details or removed entirely.
        #
        # ## Why This Matters
        #
        # Documentation is most valuable when AI assistants and human developers
        # can trust it. Redundant descriptions like `@param user [User] The user`
        # create noise without adding value, training both humans and AI to ignore
        # parameter documentation. Better to have no description (letting the type
        # speak for itself) than a redundant one.
        #
        # @example Redundant - Article + param name (will be flagged)
        #   # @param appointment [Appointment] The appointment
        #   # @param user [User] the user
        #   def process(appointment, user)
        #   end
        #
        # @example Redundant - Possessive form (will be flagged)
        #   # @param appointment [Appointment] The event's appointment
        #   def schedule(appointment)
        #   end
        #
        # @example Redundant - Type restatement (will be flagged)
        #   # @param user [User] User object
        #   # @param value [Integer] Integer value
        #   def update(user, value)
        #   end
        #
        # @example Redundant - Parameter to verb pattern (will be flagged)
        #   # @param payments [Array] Payments to count
        #   # @param user [User] User to notify
        #   def process(payments, user)
        #   end
        #
        # @example Redundant - ID pattern (will be flagged)
        #   # @param treatment_id [String] ID of the treatment
        #   # @param uuid [String] Unique identifier for the list
        #   def find(treatment_id, uuid)
        #   end
        #
        # @example Redundant - Directional date (will be flagged)
        #   # @param from [Date] from this date
        #   # @param till [Date] till this date
        #   def filter(from, till)
        #   end
        #
        # @example Redundant - Type + generic term (will be flagged)
        #   # @param payment [Payment] Payment object
        #   # @param data [Hash] Hash data
        #   def process(payment, data)
        #   end
        #
        # @example Good - No description (type is self-explanatory)
        #   # @param appointment [Appointment]
        #   # @param user [User]
        #   def process(appointment, user)
        #   end
        #
        # @example Good - Long, meaningful descriptions with context
        #   # @param date [Date, nil] the date that can describe the event starting information or nil if event did not yet start
        #   # @param user [User] the user who initiated the request and will receive notifications
        #   # @param data [Hash] configuration options for the API endpoint including timeout and retry settings
        #   def configure(date, user, data)
        #   end
        #
        # @example Good - Short but adds value beyond param name
        #   # @param count [Integer] maximum number of retries before giving up
        #   # @param timeout [Integer] seconds to wait before timing out the connection
        #   # @param enabled [Boolean] whether the feature is enabled for this account
        #   def setup(count, timeout, enabled)
        #   end
        #
        # @example Good - Starts similar but continues with valuable info
        #   # @param user [User] the current user, or guest if not authenticated
        #   # @param data [Hash] the request payload containing user preferences
        #   # @param id [String] unique identifier used for tracking across systems
        #   def track(user, data, id)
        #   end
        #
        # ## Configuration
        #
        # The validator is highly configurable to match your project's needs:
        #
        #     Tags/RedundantParamDescription:
        #       Description: 'Detects meaningless parameter descriptions.'
        #       Enabled: true
        #       Severity: convention
        #       CheckedTags:
        #         - param
        #         - option
        #       # Articles that trigger the article_param pattern
        #       Articles:
        #         - The
        #         - the
        #         - A
        #         - a
        #         - An
        #         - an
        #       # Maximum word count for redundant descriptions (longer descriptions are never flagged)
        #       MaxRedundantWords: 6
        #       # Minimum character length to consider meaningful (secondary check)
        #       MinMeaningfulLength: 15
        #       # Generic terms that trigger the type_generic pattern
        #       GenericTerms:
        #         - object
        #         - instance
        #         - value
        #         - data
        #         - item
        #         - element
        #       # Pattern toggles (enable/disable specific detection patterns)
        #       EnabledPatterns:
        #         ArticleParam: true        # "The user", "the appointment"
        #         PossessiveParam: true     # "The event's appointment"
        #         TypeRestatement: true     # "User object", "Appointment"
        #         ParamToVerb: true         # "Payments to count"
        #         IdPattern: true           # "ID of the treatment" for *_id params
        #         DirectionalDate: true     # "from this date" for from/to/till
        #         TypeGeneric: true         # "Payment object", "Hash data"
        #
        # ## Pattern Types
        #
        # The validator detects 7 different redundancy patterns:
        #
        # 1. **ArticleParam**: `"The user"`, `"the appointment"` - Article + parameter name
        # 2. **PossessiveParam**: `"The event's appointment"` - Possessive form + parameter name
        # 3. **TypeRestatement**: `"User object"`, `"Appointment"` - Just repeats the type
        # 4. **ParamToVerb**: `"Payments to count"` - Parameter name + "to" + verb
        # 5. **IdPattern**: `"ID of the treatment"` - For `_id` or `_uuid` suffixed parameters
        # 6. **DirectionalDate**: `"from this date"` - For `from`, `to`, `till` parameters
        # 7. **TypeGeneric**: `"Payment object"` - Type + generic term like "object", "instance"
        #
        # You can disable individual patterns while keeping others enabled.
        #
        # ## False Positive Prevention
        #
        # The validator uses multiple strategies to prevent false positives:
        #
        # 1. **Word count threshold**: Descriptions longer than `MaxRedundantWords` (default: 6)
        #    are never flagged, even if they start with a redundant pattern
        # 2. **EXACT pattern matching**: Only flags complete matches, not partial/prefix matches
        # 3. **Character length check**: Very short descriptions below `MinMeaningfulLength`
        #    may be flagged even if meaningful
        # 4. **Configurable patterns**: Disable patterns that don't work for your codebase
        #
        # This means `"the date that can describe the event starting information"` (9 words)
        # will never be flagged, even though it starts with "the date".
        #
        # ## Disabling
        #
        # To disable this validator:
        #
        #     Tags/RedundantParamDescription:
        #       Enabled: false
        #
        module RedundantParamDescription
        end
      end
    end
  end
end

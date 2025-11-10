# frozen_string_literal: true

# Test fixture for RedundantParamDescription validator
class RedundantParamFixtures
  # REDUNDANT EXAMPLES - Should be flagged

  # Pattern 1: Article + param name
  # @param appointment [Appointment] The appointment
  # @param user [User] the user
  # @param data [Hash] A data
  def article_param_redundant(appointment, user, data); end

  # Pattern 2: Possessive + param name
  # @param appointment [Appointment] The event's appointment
  # @param user [User] The system's user
  def possessive_param_redundant(appointment, user); end

  # Pattern 3: Type restatement
  # @param appointment [Appointment] Appointment
  # @param user [User] User object
  # @param value [Integer] Integer value
  def type_restatement_redundant(appointment, user, value); end

  # Pattern 4: param to verb
  # @param payments [Array] Payments to count
  # @param user [User] User to notify
  def param_to_verb_redundant(payments, user); end

  # Pattern 5: ID pattern
  # @param treatment_id [String] ID of the treatment
  # @param uuid [String] Unique identifier for the list
  def id_pattern_redundant(treatment_id, uuid); end

  # Pattern 6: Directional date
  # @param from [Date] from this date
  # @param till [Date] till this date
  def directional_date_redundant(from, till); end

  # Pattern 7: Type + generic term
  # @param payment [Payment] Payment object
  # @param data [Hash] Hash data
  def type_generic_redundant(payment, data); end

  # VALID EXAMPLES - Should NOT be flagged

  # Long, meaningful descriptions
  # @param date [Date, nil] the date that can describe the event starting information or nil if event did not yet start
  # @param user [User] the user who initiated the request and will receive notifications
  # @param data [Hash] configuration options for the API endpoint including timeout and retry settings
  def long_meaningful_descriptions(date, user, data); end

  # Short but adds value beyond param name
  # @param count [Integer] maximum number of retries before giving up
  # @param timeout [Integer] seconds to wait before timing out the connection
  # @param enabled [Boolean] whether the feature is enabled for this account
  def short_but_meaningful(count, timeout, enabled); end

  # No description (this is fine - validator only checks when description exists)
  # @param appointment [Appointment]
  # @param user [User]
  # @param data [Hash]
  def no_descriptions(appointment, user, data); end

  # Descriptions that start similar but continue with value
  # @param user [User] the current user, or guest if not authenticated
  # @param data [Hash] the request payload containing user preferences
  # @param id [String] unique identifier used for tracking across systems
  def starts_similar_but_valuable(user, data, id); end

  # @option opts [String] :name User's full name
  # @option opts [Integer] :age Age in years
  def with_options(opts = {}); end

  # Edge case: exactly at word count threshold but meaningful
  # @param value [Integer] the maximum retry count value
  # @param config [Hash] application level configuration data
  def at_threshold_but_meaningful(value, config); end
end

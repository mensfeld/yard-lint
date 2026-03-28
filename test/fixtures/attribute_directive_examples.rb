# frozen_string_literal: true

# Fixture for testing @!attribute directive with explicit setter methods
# See: https://github.com/mensfeld/yard-lint/issues/115

class AttributeDirectiveExamples
  # --- @!attribute [rw] with explicit getter and setter ---

  # @!attribute [rw] logger
  #
  # Sets a logger for use by this gem.
  #
  # @return [Logger]
  def logger=(value)
    @logger = value
  end

  def logger
    @logger
  end

  # --- @!attribute [rw] with just a setter ---

  # @!attribute [rw] name
  #
  # The name of the object.
  #
  # @return [String]
  def name=(value)
    @name = value
  end

  def name
    @name
  end

  # --- @!attribute [w] write-only ---

  # @!attribute [w] password
  #
  # Sets the password.
  #
  # @return [String]
  def password=(value)
    @password = value
  end

  # --- @!attribute [r] read-only (no setter, should not flag getter) ---

  # @!attribute [r] host
  #
  # The host address.
  #
  # @return [String]
  def host
    @host
  end

  # --- @!attribute with @return but no @param (the reported issue) ---

  # @!attribute [rw] timeout
  #
  # Connection timeout in seconds.
  #
  # @return [Integer]
  def timeout=(value)
    @timeout = value
  end

  def timeout
    @timeout
  end

  # --- @!attribute setter with complex body (from issue example) ---

  # @!attribute [rw] formatter
  #
  # Sets a custom formatter.
  #
  # @return [Proc]
  def formatter=(value)
    value.freeze
    @formatter = value
  end

  def formatter
    @formatter
  end

  # --- Regular setter WITHOUT @!attribute should still be checked ---

  # @return [Integer]
  def regular_setter=(value)
    @regular_setter = value
  end

  # --- Regular method with documented param should not be flagged ---

  # @param value [String] the value to process
  # @return [void]
  def process(value)
    value
  end

  # --- Regular method missing param docs should still be flagged ---

  # @return [void]
  def undocumented_param(value)
    value
  end

  # --- Regular method with multiple undocumented params ---

  # @return [void]
  def multiple_undocumented(a, b, c)
    [a, b, c]
  end

  # --- Method with some params documented and some not ---

  # @param a [String] first param
  # @return [void]
  def partially_documented(a, b)
    [a, b]
  end

  # --- @!attribute [rw] with extra @param tag (should not flag) ---

  # @!attribute [rw] level
  #
  # @param value [Symbol] the log level
  # @return [Symbol]
  def level=(value)
    @level = value
  end

  def level
    @level
  end
end

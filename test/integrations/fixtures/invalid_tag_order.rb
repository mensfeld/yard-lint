# frozen_string_literal: true

# Class with invalid tag ordering
class InvalidTagOrder
  # Tags are in wrong order (return before param)
  # @return [String] result
  # @param value [Integer] input value
  def process(value)
    value.to_s
  end

  # Another method with wrong order
  # @raise [StandardError] on error
  # @return [Boolean] success
  # @param data [Hash] input data
  def validate(data)
    raise StandardError unless data.is_a?(Hash)

    true
  end

  # Method with consecutive same tags in correct order - should NOT trigger order violation
  # @param topic [String] the topic name
  # @return [Boolean] whether the operation succeeded
  # @note This class only generates plans - actual execution requires Kafka's Java tools
  # @note Always verify broker capacity before increasing replication
  def with_multiple_notes(topic)
    true
  end

  # Method with multiple notes in correct order with other tags
  # @param config [Hash] configuration options
  # @return [void]
  # @note Configuration must be validated first
  # @note Changes take effect after restart
  # @note See also the admin documentation
  def configure_with_notes(config); end

  # Method with multiple examples in correct order - should NOT trigger order violation
  # @param value [Integer] the value to process
  # @return [Integer] the processed value
  # @example Basic usage
  #   process_example(42)
  # @example With negative value
  #   process_example(-1)
  def process_example(value)
    value * 2
  end
end

# frozen_string_literal: true

# Service class for data processing
class DataService
  # Processes data - tags in wrong order (return before param)
  # @return [Hash] processed data
  # @param data [Array] input data
  # @raise [ArgumentError] if data is invalid
  def process(data)
    raise ArgumentError, 'Invalid data' if data.nil?

    { result: data.map(&:upcase) }
  end

  # Validates input - tags in wrong order (raise before return)
  # @param input [String] input to validate
  # @raise [StandardError] if input is invalid
  # @return [Boolean] validation result
  def validate(input)
    raise StandardError, 'Empty input' if input.empty?

    true
  end
end

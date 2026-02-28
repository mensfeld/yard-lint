# frozen_string_literal: true

# Service with invalid type definitions
class TypeService
  # Process data with invalid type - InvalidType is not a real class
  # @param data [InvalidType] input data
  # @return [FakeClass] processed result
  def process(data)
    data.upcase
  end

  # Valid types should not be flagged
  # @param name [String] user name
  # @param age [Integer] user age
  # @return [Hash] user hash
  def create_user(name, age)
    { name: name, age: age }
  end

  # Another invalid type
  # @param _config [NonExistentConfig] configuration
  # @return [Array<UnknownType>] results
  def configure(_config)
    []
  end
end

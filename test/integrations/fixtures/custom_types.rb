# frozen_string_literal: true

# Example class using custom/non-standard type annotations
class CustomTypesExample
  # Method with custom type that should be valid with ExtraTypes config
  # @param handler [Callable] callback function
  # @return [Result] operation result
  def process_with_callback(handler)
    handler.call
  end

  # Method with duck-typed parameter
  # @param data [Duck] duck-typed object
  # @return [String] processed data
  def process_duck(data)
    data.to_s
  end

  # Method with custom serializable type
  # @param object [JsonSerializable] object to serialize
  # @return [String] JSON string
  def serialize(object)
    object.to_json
  end

  # Method with standard Ruby type for comparison
  # @param text [String] input text
  # @return [Integer] length
  def standard_type(text)
    text.length
  end

  # Method with invalid/nonsense type (should always fail)
  # @param bad_param [$%^&*(] invalid type syntax
  # @return [???] question marks not valid
  def invalid_types(bad_param)
    bad_param
  end
end

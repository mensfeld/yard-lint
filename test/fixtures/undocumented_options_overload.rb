# frozen_string_literal: true

# Methods with options hashes documented at top level and inside @overload.
class UndocumentedOptionsOverload
  # Connects with options documented inside an overload.
  # @overload connect(options = {})
  #   @param options [Hash] connection options
  #   @option options [Integer] :port port number
  #   @return [void]
  def connect(options = {})
    options
  end

  # Binds with options documented at top level.
  # @param options [Hash] binding options
  # @option options [Integer] :port port number
  # @return [void]
  def bind(options = {})
    options
  end

  # Listens with an overload that documents no @option tags.
  # @overload listen(options = {})
  #   @param options [Hash] listening options
  #   @return [void]
  def listen(options = {})
    options
  end
end

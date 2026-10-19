# frozen_string_literal: true

# Methods with redundant and meaningful @param descriptions at top level and
# inside @overload.
class RedundantParamDescriptionOverload
  # Builds with a redundant description inside an overload.
  # @overload build(name)
  #   @param name [String] the name
  #   @return [String] the result
  def build(name)
    name
  end

  # Renders with a redundant description at top level.
  # @param title [String] the title
  # @return [String] the result
  def render(title)
    title
  end

  # Connects with a redundant @option description inside an overload.
  # @overload connect(opts = {})
  #   @param opts [Hash] settings passed to the socket
  #   @option opts [Integer] :port the port
  #   @return [void]
  def connect(opts = {})
    opts
  end

  # Parses with a meaningful description inside an overload.
  # @overload parse(source)
  #   @param source [String] raw input read from the config file
  #   @return [String] the result
  def parse(source)
    source
  end
end

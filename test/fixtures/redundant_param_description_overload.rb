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

  # Parses with a meaningful description inside an overload.
  # @overload parse(source)
  #   @param source [String] raw input read from the config file
  #   @return [String] the result
  def parse(source)
    source
  end
end

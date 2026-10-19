# frozen_string_literal: true

# Methods with badly and well styled @example code at top level and inside @overload.
class ExampleStyleOverload
  # Builds with a badly styled example inside an overload.
  # @overload build(name)
  #   @param name [String] the name
  #   @return [String] the result
  #   @example Build overload
  #     build( "a" )
  def build(name)
    name
  end

  # Renders with a badly styled example at top level.
  # @param name [String] the name
  # @return [String] the result
  # @example Render top level
  #   render( "a" )
  def render(name)
    name
  end

  # Parses with a well styled example inside an overload.
  # @overload parse(name)
  #   @param name [String] the name
  #   @return [String] the result
  #   @example Parse overload
  #     parse('a')
  def parse(name)
    name
  end
end

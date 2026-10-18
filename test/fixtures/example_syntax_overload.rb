# frozen_string_literal: true

# Methods with broken and valid @example code at top level and inside @overload.
class ExampleSyntaxOverload
  # Builds with a broken example inside an overload.
  # @overload build(name)
  #   @param name [String] the name
  #   @return [String] the result
  #   @example Broken
  #     build('a' +
  def build(name)
    name
  end

  # Renders with a broken example at top level.
  # @param name [String] the name
  # @return [String] the result
  # @example Broken
  #   render('a' +
  def render(name)
    name
  end

  # Parses with a valid example inside an overload.
  # @overload parse(name)
  #   @param name [String] the name
  #   @return [String] the result
  #   @example Valid
  #     parse('a')
  def parse(name)
    name
  end
end

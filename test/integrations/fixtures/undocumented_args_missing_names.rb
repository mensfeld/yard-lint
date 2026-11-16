# frozen_string_literal: true

# Fixtures for Documentation/UndocumentedMethodArguments messages that name
# the missing arguments.
class UndocumentedArgsMissingNames
  # Greets someone
  # @param nme [String] the name
  # @return [String]
  def greet(name); end

  def undocumented(a, b = 1); end

  # Only the keyword is undocumented
  # @param item [String] the item
  def keyword_missing(item, limit:); end

  def destructured((a, b), c); end

  def destructured_multiline((a,
                              b)); end

  def repeated(_, _, x); end

  # Combines two values
  # @return [UndocumentedArgsMissingNames]
  def |(other); end
end

# frozen_string_literal: true

# Fixture for the shared-docstring tests.
#
# One comment block can document more than one code object. An attr_accessor
# registers a reader and a writer, both carrying the same docstring at the same
# location, so a layout offense in that comment belongs to one place in the
# source and must be reported once rather than once per generated method.
class SharedDocstringExample
  # Documented with no blank line between the param and return tags
  #
  # @param value [String] the value
  # @return [String] the value
  attr_accessor :value

  # Documented with a blank line between every tag
  #
  # @param other [String] the other
  #
  # @return [String] the other
  attr_accessor :other

  # A plain method with the same shape, to prove the dedup is not swallowing
  # unrelated offenses
  #
  # @param thing [String] the thing
  # @return [String] the thing
  def echo(thing)
    thing
  end
end

# frozen_string_literal: true

# Fixture for docstrings YARD did not read from a comment block sitting above a
# definition.
#
# A `@!method` directive creates a documented object with no docstring line
# range - the same signal `module_function_copy?` uses to recognize the
# normalized half of a module_function pair - so these objects must still be
# linted normally. Every method below is documented with no blank line between
# its param and return tags, so every one of them is an offense.

# A directive-created method with no counterpart of the opposite scope.
class DirectiveSoloExample
  # @!method solo(a)
  #   Documented with no blank line between the param and return tags
  #   @param a [String] the a
  #   @return [String] the a
  def method_missing(name, *args) = super

  # @return [Boolean] whether the method is handled
  def respond_to_missing?(name, include_private = false) = super
end

# A directive-created method whose opposite-scope namesake is defined normally,
# at a different line.
class DirectiveAndDefinedExample
  # @!method paired(a)
  #   Documented with no blank line between the param and return tags
  #   @param a [String] the a
  #   @return [String] the a
  def method_missing(name, *args) = super

  # Documented with no blank line between the param and return tags
  #
  # @param a [String] the a
  # @return [String] the a
  def self.paired(a) = a
end

# Both halves of a same-named pair, created by directives at one location, with
# neither flagged by YARD as a module function.
class DirectivePairExample
  # @!method both(a)
  #   Documented with no blank line between the param and return tags
  #   @param a [String] the a
  #   @return [String] the a
  #
  # @!method self.both(a)
  #   Documented with no blank line between the param and return tags
  #   @param a [String] the a
  #   @return [String] the a
  def method_missing(name, *args) = super
end

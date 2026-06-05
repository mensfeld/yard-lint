# frozen_string_literal: true

# Fixture for ExtraTypes integration tests.
# These methods use non-standard lowercase type names that are NOT valid Ruby
# constants and are NOT in ALLOWED_DEFAULTS - they would normally produce
# InvalidTagType offenses. With ExtraTypes configured, they should be accepted.
#
# Note: uppercase type names (e.g. Callable, Result) are NOT flagged by default
# because Kernel.const_defined? returns false (not nil) for syntactically valid
# constant names, which yard-lint treats as "at least recognised". Only lowercase
# names that raise NameError (e.g. generic, callable_type) are flagged.

class ExtraTypes
  # Solargraph-style generic type parameters (YARD proposal: lsegal/yard#1683).
  # @param store [Hash{Class<generic<T>> => Set<generic<T>>}] generic type map
  # @return [Array<generic<T>>] generic collection
  def generic_types(store); end

  # @return [generic<T>] standalone generic type parameter
  def standalone_generic; end

  # Multiple custom lowercase pseudo-types.
  # @param handler [generic, awaitable] multiple non-standard types
  def multiple_custom(handler); end
end

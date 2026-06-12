# frozen_string_literal: true

# Fixture for @overload documentation tests. YARD stores tags written inside
# @overload blocks on the overload's own docstring, so validators reading
# object.tags directly do not see them.
class OverloadDocumented
  # @overload fetch(key)
  #   @param key [Symbol] the key
  #   @return [Object] the value
  def fetch(key)
    key
  end

  # @overload configure(opts)
  #   @param opts [Hash] configuration options
  #   @option opts [Boolean] :fast whether to skip validations
  def configure(opts)
    opts
  end

  # @overload legacy(value)
  #   @param value [Object] anything at all
  def legacy(value)
    value
  end
end

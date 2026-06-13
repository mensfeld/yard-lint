# frozen_string_literal: true

# Internal API surface with a multi-line @api tag.
# @api private
#   for internal use only, not part of the public contract
class ApiTagContinuation
  # An internal helper documented with @api private plus a description line.
  # @api private
  #   do not call this directly
  # @return [void]
  def helper
    nil
  end

  # A method with a genuinely invalid @api value.
  # @api bogus
  # @return [void]
  def weird
    nil
  end
end

# frozen_string_literal: true

# Fixture for testing that type syntax errors inside @overload blocks ARE detected.
# Uses malformed type syntax that YARD's TypesExplainer::Parser will reject.

class OverloadInvalidTypes
  # @overload convert(name)
  #   @param name [Array<>] empty generic is invalid syntax
  #   @return [String] the result
  # @overload convert(id)
  #   @param id [Integer] a valid type
  #   @return [String] valid return
  def convert(arg)
    arg
  end
end

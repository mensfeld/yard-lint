# frozen_string_literal: true

# Fixture for testing type validation inside @overload blocks.
# YARD stores @overload inner tags on a separate docstring, so validators
# must explicitly traverse them.

class OverloadTypes
  # @overload process(name)
  #   @param name [String] a string name
  #   @return [String] the processed name
  # @overload process(id)
  #   @param id [Integer] a numeric id
  #   @return [Integer] the processed id
  def process(arg)
    arg
  end

  # @overload find(query)
  #   @param query [Hash{Symbol => String}] search criteria
  #   @return [Array<String>] matching results
  # @overload find(id)
  #   @param id [Integer] record id
  #   @return [String, nil] the found record or nil
  def find(arg)
    arg
  end
end

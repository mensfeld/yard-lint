# frozen_string_literal: true

# Directives that refer to a module and a class defined in directives_b.rb
class DirectivesA
  # @!parse include DirectivesB
  # @!parse extend DirectivesB
  # @!method build(input)
  #   Builds a label from the input
  #   @param input [String] text to wrap
  #   @return [DirectivesBase] wrapped label
  # @!attribute [r] label
  #   @return [DirectivesBase] current label
  # @!attribute [rw] size
  #   @return [Integer] number of labels
end

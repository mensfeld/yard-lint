# frozen_string_literal: true

# Base class reopened through directives in directives_a.rb
class DirectivesBase
  # @!method wrap(input)
  #   Wraps the input
  #   @param input [String] text to wrap
  #   @return [String] wrapped text
end

# Helpers mixed into DirectivesA through @!parse
module DirectivesB
  # @!attribute [r] prefix
  #   @return [String] label prefix
end

class DirectivesA < DirectivesBase
  # @!method reset
  #   Resets the labels
  #   @return [void]
end

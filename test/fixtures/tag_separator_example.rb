# frozen_string_literal: true

# Fixture for TagSeparator tests.
class TagSeparatorExample
  # Computes and stores a result
  #
  # @example Usage
  #   compute
  #   @result = compute
  #
  # @return [void]
  def perform
    @result = nil
  end

  # Combines two values with every tag blank-line separated
  #
  # @param foo [String] the foo
  #
  # @param bar [String] the bar
  #
  # @return [String] the combined value
  def combined(foo, bar)
    foo + bar
  end

  # Configures with option tags clustered under the hash param
  #
  # @param opts [Hash] the options
  # @option opts [String] :name the name
  # @option opts [Integer] :age the age
  #
  # @return [void]
  def configure(opts)
    opts
  end
end

# frozen_string_literal: true

# Base class with abstract methods.
class AbstractMultilineRaise
  # @abstract Subclasses must implement this.
  # @return [void]
  def multiline_raise
    raise NotImplementedError,
          'subclasses must provide their own behavior'
  end

  # @abstract Subclasses must implement this.
  # @return [Integer]
  def has_real_implementation
    base_value * 2
  end
end

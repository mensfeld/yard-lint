# frozen_string_literal: true

# Base class whose abstract methods guard with `fail`, a built-in alias of `raise`.
class AbstractFailAlias
  # @abstract Subclasses must implement this.
  # @return [void]
  def fail_guard
    fail NotImplementedError # rubocop:disable Style/SignalException
  end

  # @abstract Subclasses must implement this.
  # @return [void]
  def fail_with_message
    # rubocop:disable Style/SignalException
    fail NotImplementedError, 'subclasses must provide their own behavior'
    # rubocop:enable Style/SignalException
  end

  # @abstract Subclasses must implement this.
  # @return [Integer]
  def has_real_implementation
    base_value * 2
  end
end

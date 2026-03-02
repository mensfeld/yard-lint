# frozen_string_literal: true

# Status checker class
class StatusChecker
  # Checks if active - no docs
  def active?
    true
  end

  # Checks if ready - no docs
  def ready?
    false
  end

  # Checks if valid - has proper docs
  # @return [Boolean] true if valid
  def valid?
    true
  end
end

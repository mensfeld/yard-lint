# frozen_string_literal: true

# Base with an abstract method delegating to super.
class AbstractAllowedImpl
  # @abstract Subclasses implement this.
  # @return [void]
  def must_implement
    super
  end
end

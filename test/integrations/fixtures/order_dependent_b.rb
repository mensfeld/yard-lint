# frozen_string_literal: true

# Defines the methods aliased in order_dependent_a.rb
class OrderCore
  # Runs things
  # @return [void]
  def run; end
end

# Defines the module functions declared in order_dependent_a.rb
module OrderUtil
  # Tells if it is ready
  # @return [Boolean] true when ready
  def ready?; end

  # Does the work
  # @return [void]
  def work; end
end

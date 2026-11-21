# frozen_string_literal: true

# Module functions defined under a bare module_function
module UndocBare
  module_function

  def run(value)
    value
  end

  def ready?
    true
  end

  # Documented
  # @return [Boolean] true
  def documented?
    true
  end
end

# Module functions passed to module_function by name
module UndocSymbol
  def run
    1
  end
  module_function :run

  def ready?
    true
  end
  module_function :ready?

  module_function def inline
    1
  end

  module_function def inline?
    true
  end

  # Documented
  # @return [Integer] one
  def documented
    1
  end
  module_function :documented

  private

  def helper
    1
  end
end

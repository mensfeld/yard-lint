# frozen_string_literal: true

require_relative "./macro_a"

# Macro usage with definition in another file
class MacroB
  # @macro testing
  def self.b_method(some_key)
    MacroA.a_method(some_key)
  end
end

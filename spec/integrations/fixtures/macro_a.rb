# frozen_string_literal: true

# Macro definition and usage in the same file
class MacroA
  # @!macro testing
  #   @param some_key [String] Some Key
  # @macro testing
  def self.a_method(some_key)
    puts some_key
  end
end

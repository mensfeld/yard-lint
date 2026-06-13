# frozen_string_literal: true

# Exercises the unknown-parameter suggestion engine.
class UnknownParamSuggestions
  # @param apple [String] first
  # @param banana [String] second
  # @return [void]
  def first(apple, banana)
    [apple, banana]
  end

  # @param chery [String] typo of cherry
  # @return [void]
  def second(cherry, grape)
    [cherry, grape]
  end

  # @param nme [String] typo of name
  # @return [void]
  def self.build(name)
    name
  end

  # @param naem [String] typo of name
  # @return [void]
  def configure(items = [1, 2], mode: :fast, name: nil)
    [items, mode, name]
  end
end

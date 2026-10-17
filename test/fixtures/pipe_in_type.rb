# frozen_string_literal: true

# Types with '|', which is not YARD type syntax
class PipeInType
  # Finds a node
  # @return [String | nil] the node
  def find = nil

  # Fetches a value
  # @param key [Symbol|String] the key
  # @return [Object] the value
  def fetch(key) = key

  # Formats a rate
  # @return [Rate%|nil] the rate
  def rate = nil
end

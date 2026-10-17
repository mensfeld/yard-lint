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

  # Joins two parts
  # @param part [String |
  #   nil] the part
  # @return [void]
  def join(part) = part

  # Splits a list
  # @param list [Array<String,
  #   Integer] the list
  # @return [void]
  def split(list) = list
end

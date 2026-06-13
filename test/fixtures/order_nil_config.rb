# frozen_string_literal: true

# A class whose method documents tags in the wrong order.
class OrderNilConfig
  # @return [String] the value
  # @param key [Symbol] the key
  def fetch(key)
    key.to_s
  end
end

# frozen_string_literal: true

# Fixture for offense attribution tests: several objects with distinct tag
# offenses, each expecting its own message payload. Guards against parallel
# location/payload arrays drifting out of sync in the Order and
# TagGroupSeparator parsers.
class TagOffenseAttribution
  # Reads a value
  # @return [String] the value
  # @param key [Symbol] the key
  def read(key)
    key.to_s
  end

  # Writes a value
  # @example Writing
  #   TagOffenseAttribution.new.write(:a)
  # @param key [Symbol] the key
  def write(key)
    key
  end
end

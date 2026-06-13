# frozen_string_literal: true

# Methods with options-named params of differing kinds.
class UndocumentedOptionsNonHash
  # Enables a single named option.
  # @param option [Symbol] the option to enable
  # @return [void]
  def enable(option)
    option
  end

  # Configures from an options hash without documenting @option tags.
  # @param options [Hash] the configuration options
  # @return [void]
  def configure(options)
    options
  end
end

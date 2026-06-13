# frozen_string_literal: true

# Methods whose options-named parameters are not actually option hashes.
class OptionTagsNonHash
  # Runs with a boolean flag named like an options hash.
  # @param options [Boolean] whether to apply options
  # @return [void]
  def run_flag(options: false)
    options
  end

  # Processes a list named like an options hash.
  # @param opts [Array<String>] list of option names
  # @return [void]
  def process(opts)
    opts
  end

  # Genuinely takes an options hash but documents no @option tags.
  # @param options [Hash] the configuration options
  # @return [void]
  def configure(options)
    options
  end
end

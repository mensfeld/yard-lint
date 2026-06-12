# frozen_string_literal: true

# Fixture for @option tag data tests. YARD's OptionTag carries its types and
# description on the nested pair tag (tag.pair) - tag.types and tag.text are
# nil on the OptionTag itself, so validators reading them directly skip every
# @option tag.
class OptionTagData
  # Configures the run
  # @param opts [Hash] runtime configuration options
  # @option opts [strng] :mode processing mode
  # @option opts [Hash<Symbol, String>] :map keys to labels mapping
  # @option opts [Object] :raw raw payload passthrough
  # @option opts [String] :name the name
  # @return [void]
  def call(opts)
    opts
  end
end

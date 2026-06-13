# frozen_string_literal: true

class TagTypePositionMisfires
  # Configures with options.
  # @option opts [Boolean] :enabled whether enabled
  # @return [void]
  def configure(opts)
    opts
  end

  # A detached comment in type-first form, separated by a blank line.
  # @param [String] name the name

  def process(name)
    name
  end
end

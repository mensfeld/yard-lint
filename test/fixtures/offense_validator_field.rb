# frozen_string_literal: true

# Triggers AbstractMethods and OptionTags offenses.
class OffenseValidatorField
  # @abstract Subclasses must implement this.
  # @return [void]
  def abstract_with_impl
    perform_real_work
  end

  # Configures the component from an options hash.
  # @param options [Hash] the configuration options
  # @return [void]
  def configure(options)
    options
  end
end

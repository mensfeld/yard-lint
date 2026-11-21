# frozen_string_literal: true

# Defines a macro, so the files are parsed twice
class PrivateConstantMacro
  # @!macro [new] private_constant_label
  #   @return [String] the label
  def label
    'label'
  end
end

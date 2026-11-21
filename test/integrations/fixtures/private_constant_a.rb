# frozen_string_literal: true

# Hides a constant defined in private_constant_b.rb
module PrivateConstantHolder
  private_constant :SECRET
end

# frozen_string_literal: true

# Fixture for the module_function duplicate-registration tests.
#
# `module_function` makes YARD register one definition twice - as a public class
# method and as a private instance method - and builds one half of the pair with
# CodeObjects::Base#copy_to, which assigns Docstring#to_raw of the original. That
# reconstruction preserves content but not layout: the blank lines between tags
# are gone. Every separated method below must therefore be reported as valid even
# though half of what YARD registers for it has no blank lines at all.
#
# Which half is the reconstruction differs per form, so all three forms are
# covered here.

# Bare form: the private instance copy is the reconstruction.
#
# @api private
#
module BareModuleFunctionExample
  module_function

  # Documented with a blank line between every tag
  #
  # @param foo [String] the foo
  #
  # @return [String] the foo
  def bare_separated(foo)
    foo
  end

  # Documented with no blank line between the param and return tags
  #
  # @param foo [String] the foo
  # @return [String] the foo
  def bare_unseparated(foo)
    foo
  end
end

# Symbol form: the class method copy is the reconstruction.
module SymbolModuleFunctionExample
  # Documented with a blank line between every tag
  #
  # @param foo [String] the foo
  #
  # @return [String] the foo
  def symbol_separated(foo)
    foo
  end

  module_function :symbol_separated
end

# Decorator form: neither half keeps a docstring line range, and the class
# method copy is the reconstruction.
module DecoratorModuleFunctionExample
  # Documented with a blank line between every tag
  #
  # @param foo [String] the foo
  #
  # @return [String] the foo
  module_function def decorator_separated(foo)
    foo
  end
end

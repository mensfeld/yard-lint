# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        # OverloadConsistency validator
        #
        # Checks each `@overload` against its own signature. YARD checks `@param`
        # names only on the method's primary docstring, so tags inside an
        # overload are never compared with the overload's parameters. This
        # validator reports:
        #
        # - a `@param` that names no parameter of its overload's signature
        # - a parameter with no `@param` in an overload that documents at least
        #   one other parameter (splat and block parameters are not required)
        # - an overload with no `@return` when another overload of the same
        #   method has one and the method docstring itself has none
        #
        # Overloads that use argument forwarding (`...`) or anonymous splat or
        # block parameters are not checked for unknown names. This validator is
        # enabled by default.
        #
        # @example Bad - @param does not match the overload's signature
        #   # @overload fetch(key)
        #   #   @param name [String] the key
        #   #   @return [Object]
        #   def fetch(*args); end
        #
        # @example Good - each overload documents its own parameters
        #   # @overload fetch(key)
        #   #   @param key [String] the key
        #   #   @return [Object]
        #   # @overload fetch(key, default)
        #   #   @param key [String] the key
        #   #   @param default [Object] value when the key is missing
        #   #   @return [Object]
        #   def fetch(*args); end
        #
        # ## Configuration
        #
        # To disable this validator:
        #
        #     Tags/OverloadConsistency:
        #       Enabled: false
        module OverloadConsistency
        end
      end
    end
  end
end

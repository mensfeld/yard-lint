# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Semantic
        # AbstractMethods validator
        #
        # Ensures that methods marked with `@abstract` are actually abstract (not
        # implemented). Abstract methods should either raise NotImplementedError or
        # be empty stubs, not contain actual implementation logic. This validator
        # is enabled by default.
        #
        # @example Bad - @abstract tag on implemented method
        #   # @abstract
        #   def process
        #     puts "This is actually implemented!"
        #   end
        #
        # @example Good - @abstract method raises NotImplementedError
        #   # @abstract
        #   def process
        #     raise NotImplementedError
        #   end
        #
        # @example Good - @abstract method is empty
        #   # @abstract
        #   def process
        #   end
        #
        # ## Configuration
        #
        # To disable this validator:
        #
        #     Semantic/AbstractMethods:
        #       Enabled: false
        #
        module AbstractMethods
        end
      end
    end
  end
end

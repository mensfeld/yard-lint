# frozen_string_literal: true

module Yard
  module Lint
    # Parsers for extracting offense details from YARD command output
    module Parsers
      # Base class used for all the subparsers of a yard parser
      class Base
        class << self
          attr_accessor :regexps
        end

        # @param string [String] string from which we want to extract informations
        # @param regexp_name [Symbol] name of a regexp used to extract a given information
        # @return [Array<String>] array with extracted details or empty array if there's
        #   nothing worth extracting
        def match(string, regexp_name)
          string.match(self.class.regexps[regexp_name])&.captures || []
        end
      end
    end
  end
end

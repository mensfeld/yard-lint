# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module TagSeparator
          # Parser for extracting tag separator violations from raw validator output.
          #
          # @example Output format (skip-lint)
          #   /path/to/file.rb:10: ClassName#method_name
          #   param->param,param->return
          class Parser < Parsers::Base
            # Parses raw validator output into structured offense data.
            #
            # @param raw_output [String] raw validator output string
            #
            # @return [Array<Hash>] array of hashes with offense details
            def call(raw_output)
              return [] if raw_output.nil? || raw_output.empty?

              entries_by_location = {}

              raw_output.split("\n").each_slice(2).each do |location, separators|
                next if location.nil? || separators.nil?

                # The location line is already a unique identifier for the
                # documented object (file, line and title); using it directly
                # as the key avoids collisions that a normalizing regexp could
                # accidentally introduce between distinct paths/methods.
                key = location.strip

                if separators == "valid"
                  entries_by_location[key] = "valid"
                else
                  entries_by_location[key] ||= [location, separators]
                end
              end

              entries_by_location.delete_if { |_key, value| value == "valid" }

              location_parser = Validators::Documentation::UndocumentedMethodArguments::Parser.new

              # Parse each location together with its own separators so that an
              # unparseable location line drops only its own offense instead of
              # shifting the separators of all offenses that follow it
              entries_by_location.values.filter_map do |location, separators|
                offense = location_parser.call(location).first
                next unless offense

                offense[:separators] = separators
                offense
              end
            end
          end
        end
      end
    end
  end
end

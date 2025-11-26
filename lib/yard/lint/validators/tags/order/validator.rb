# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module Order
          # Runs a query that will pick all the objects that have docs with tags in an invalid
          #   order. By invalid we mean, that they are not as defined in the settings.
          class Validator < Base
            # Enable in-process execution with all visibility
            in_process visibility: :all

            # Execute query for a single object during in-process execution.
            # Checks if tags appear in the configured order.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            # @return [void]
            def in_process_query(object, collector)
              return if object.is_alias?

              # Extract @tag names from docstring
              tag_pattern = /^@(\S+)/
              doc_tags = object.docstring.all.scan(tag_pattern).flatten

              # Remove consecutive duplicates
              accu = []
              doc_tags.each do |param|
                accu << param unless accu.last == param
              end

              # Filter to only configured tags
              order = tags_order.dup
              order.delete_if { |el| !accu.include?(el) }
              accu.delete_if { |el| !order.include?(el) }

              # Compare order using base-36 encoding
              tags_orders = order.join.to_i(36)
              accus = accu.join.to_i(36)

              collector.puts "#{object.file}:#{object.line}: #{object.title}"

              if accus != tags_orders
                collector.puts order.join(',')
              else
                collector.puts 'valid'
              end
            end

            private

            # @return [Array<String>] tags order
            def tags_order
              config.validator_config('Tags/Order', 'EnforcedOrder')
            end
          end
        end
      end
    end
  end
end

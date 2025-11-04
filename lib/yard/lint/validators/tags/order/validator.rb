# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module Order
          # Runs a query that will pick all the objects that have docs with tags in an invalid
        #   order. By invalid we mean, that they are not as defined in the settings.
          class Validator < Base
            private

          # Runs yard list query with proper settings on a given dir and files
          # @param dir [String] dir where the yard db is (or where it should be generated)
          # @param escaped_file_names [String] files for which we want to get the stats
          # @return [Hash] shell command execution hash results
            def yard_cmd(dir, escaped_file_names)
              cmd = <<~CMD
            yard list \
            --private \
            --protected \
            --query #{query} \
            -b #{Shellwords.escape(dir)} \
              #{escaped_file_names}
          CMD

              result = shell(cmd)
              result[:stdout] = { result: result[:stdout], tags_order: tags_order }
              result
            end

          # @return [String] multiline yard query that we use to find methods with
          #   tags that are not in the valid order
          # @note We need to print things for all of the elements as some of them
          #   are listed in yard twice (for example module functions), and for the
          #   second time, yard injects things by itself making it impossible to
          #   figure out whether the order is ok or now. That's why we print all and those
          #   that are ok, we mark with 'valid' and if it is reported later as invalid again,
          #   we know, that it is valid
            def query
              <<-QUERY
            '
              tags_order = #{query_array(tags_order)}
              accu = []
              str = "@"
              slash = 92.chr
              regexp = "^"+str+"("+slash+"S+)"
              doc_tags = object.docstring.all.scan(Regexp.new(regexp)).flatten

              doc_tags.each do |param|
                accu << param unless accu.last == param
              end

              tags_order.delete_if { |el| !accu.include?(el) }
              accu.delete_if { |el| !tags_order.include?(el) }

              tags_orders = tags_order.join.to_i(36)
              accus = accu.join.to_i(36)

              puts object.file + ":" + object.line.to_s + ": " + object.title

              if accus != tags_orders && !is_alias?
                puts tags_order.join(",")
              else
                puts "valid"
              end

              false
            ' \\
          QUERY
            end

          # @return [Array<String>] tags order
            def tags_order
              config.tags_order
            end

          # @param elements [Array<String>] array of elements that we want to convert into
          #   a string ruby yard query array form
          # @return [String] array of elements for yard query converted into a string
            def query_array(elements)
              "[#{elements.map { |type| "\"#{type}\"" }.join(",")}]"
            end
        end
        end
      end
    end
  end
end
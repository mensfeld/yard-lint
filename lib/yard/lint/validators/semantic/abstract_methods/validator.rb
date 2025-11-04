# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Semantic
        module AbstractMethods
          # Validator to check @abstract methods have proper implementation
          class Validator < Base
            private

          # Runs yard list query to find abstract methods with implementation
          # @param dir [String] dir where the yard db is (or where it should be generated)
          # @param escaped_file_names [String] files for which we want to get the stats
          # @return [Hash] shell command execution hash results
            def yard_cmd(dir, escaped_file_names)
              cmd = <<~CMD
            yard list \
            --private \
            --protected \
            -b #{Shellwords.escape(dir)} \
              #{escaped_file_names}
          CMD
              cmd = cmd.tr("\n", ' ')
              cmd = cmd.gsub('yard list', "yard list --query #{query}")

              shell(cmd)
            end

          # @return [String] yard query to find abstract methods with implementation
            def query
              <<~QUERY
            '
              if object.has_tag?(:abstract) && object.is_a?(YARD::CodeObjects::MethodObject)
                  # Check if method has actual implementation (not just NotImplementedError)
                source = object.source rescue nil
                if source && !source.empty?
                    # Simple heuristic: abstract methods should be empty or raise NotImplementedError
                  lines = source.split("\\n").map(&:strip).reject(&:empty?)
                    # Skip def line and end
                  body_lines = lines[1...-1] || []

                  has_real_implementation = body_lines.any? do |line|
                    !line.start_with?('#') &&
                    !line.include?('NotImplementedError') &&
                    !line.include?('raise') &&
                    line != 'end'
                    end

                  if has_real_implementation
                    puts object.file + ':' + object.line.to_s + ': ' + object.title
                    puts 'has_implementation'
                    end
                  end
                end
              false
            '
            QUERY
            end
        end
        end
      end
    end
  end
end
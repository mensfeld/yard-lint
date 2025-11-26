# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Semantic
        module AbstractMethods
          # Validator to check @abstract methods have proper implementation
          class Validator < Base
            # Enable in-process execution with all visibility
            in_process visibility: :all

            # Execute query for a single object during in-process execution.
            # Checks if @abstract methods have implementation.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            # @return [void]
            def in_process_query(object, collector)
              return unless object.has_tag?(:abstract)
              return unless object.is_a?(YARD::CodeObjects::MethodObject)

              # Check if method has actual implementation (not just NotImplementedError)
              source = object.source rescue nil
              return unless source && !source.empty?

              # Simple heuristic: abstract methods should be empty or raise NotImplementedError
              lines = source.split("\n").map(&:strip).reject(&:empty?)
              # Skip def line and end
              body_lines = lines[1...-1] || []

              has_real_implementation = body_lines.any? do |line|
                !line.start_with?('#') &&
                  !line.include?('NotImplementedError') &&
                  !line.include?('raise') &&
                  line != 'end'
              end

              return unless has_real_implementation

              collector.puts "#{object.file}:#{object.line}: #{object.title}"
              collector.puts 'has_implementation'
            end

            private

            # Runs YARD list query to find abstract methods with implementation
            # @param dir [String] dir where the YARD db is (or where it should be generated)
            # @param file_list_path [String] path to temp file containing file paths (one per line)
            # @return [Hash] shell command execution hash results
            def yard_cmd(dir, file_list_path)
              cmd = <<~CMD
                cat #{Shellwords.escape(file_list_path)} | xargs yard list \
                --private \
                --protected \
                -b #{Shellwords.escape(dir)}
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

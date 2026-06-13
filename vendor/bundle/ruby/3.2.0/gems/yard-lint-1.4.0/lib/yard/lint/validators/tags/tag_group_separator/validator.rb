# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module TagGroupSeparator
          # Validates that blank lines separate different groups of YARD documentation tags.
          #
          # This validator enforces visual separation between semantically different tag
          # groups (e.g., @param tags should be separated from @return tags by a blank line).
          class Validator < Base
            # Enable in-process execution with all visibility
            in_process visibility: :all

            # Execute query for a single object during in-process execution.
            # Checks if different tag groups are separated by blank lines.
            #
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            #
            # @return [void]
            def in_process_query(object, collector)
              return if object.is_alias?

              docstring = object.docstring.all
              return if docstring.nil? || docstring.empty?

              missing_separators = find_missing_separators(docstring)

              collector.puts "#{object.file}:#{object.line}: #{object.title}"

              if missing_separators.empty?
                collector.puts 'valid'
              else
                collector.puts missing_separators.map { |s| "#{s[:from]}->#{s[:to]}" }.join(',')
              end
            end

            private

            # Find all locations where a blank line separator is missing between tag groups.
            #
            # @param docstring [String] the raw docstring content
            #
            # @return [Array<Hash>] array of hashes with :from and :to group names
            def find_missing_separators(docstring)
              lines = docstring.split("\n")
              missing = []

              previous_group = require_after_description? ? 'description' : nil
              had_blank_line = true

              lines.each do |line|
                stripped = line.strip

                if stripped.empty?
                  had_blank_line = true
                  next
                end

                if stripped.start_with?('@')
                  tag_name = stripped.match(/^@(\S+)/)&.captures&.first
                  next unless tag_name

                  current_group = group_for_tag(tag_name)

                  if previous_group && current_group != previous_group && !had_blank_line
                    missing << { from: previous_group, to: current_group }
                  end

                  previous_group = current_group
                elsif previous_group.nil? && require_after_description?
                  # Non-tag, non-blank line (continuation or description)
                  # Only set description group if we haven't seen tags yet
                  previous_group = 'description'
                end

                had_blank_line = false
              end

              missing
            end

            # Determine which group a tag belongs to.
            #
            # @param tag_name [String] the tag name without the @ prefix
            #
            # @return [String] the group name, or the tag name itself if not in any group
            def group_for_tag(tag_name)
              tag_groups.each do |group_name, tags|
                return group_name if tags.include?(tag_name)
              end

              # Tags not in any configured group are their own group
              tag_name
            end

            # @return [Hash] configured tag groups
            def tag_groups
              @tag_groups ||= config.validator_config('Tags/TagGroupSeparator', 'TagGroups') ||
                              Config.defaults['TagGroups']
            end

            # @return [Boolean] whether to require separator after description
            def require_after_description?
              @require_after_description ||= config.validator_config(
                'Tags/TagGroupSeparator',
                'RequireAfterDescription'
              ) || false
            end
          end
        end
      end
    end
  end
end

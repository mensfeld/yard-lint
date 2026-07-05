# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module TagSeparator
          # Validates that a blank line separates every pair of consecutive YARD tags.
          #
          # Unlike {TagGroupSeparator}, which only separates different tag groups,
          # this validator requires a blank line between all consecutive tags,
          # including same-type tags such as sibling @param tags. Tags listed in
          # the Exempt option may immediately follow the previous tag.
          class Validator < Base
            # Enable in-process execution with all visibility
            in_process visibility: :all

            # Execute query for a single object during in-process execution.
            # Checks if consecutive tags are separated by blank lines.
            #
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            #
            # @return [void]
            def in_process_query(object, collector)
              # is_alias? exists only on method objects; on namespace objects
              # YARD's method_missing raises NameError, so guard by type first
              return if object.type == :method && object.is_alias?

              docstring = object.docstring.all
              return if docstring.nil? || docstring.empty?

              transitions = offending_transitions(docstring)

              collector.puts "#{object.file}:#{object.line}: #{object.title}"

              if transitions.empty?
                collector.puts "valid"
              else
                collector.puts transitions.map { |transition| "#{transition[:from]}->#{transition[:to]}" }.join(",")
              end
            end

            private

            # Find all locations where a blank line separator is missing between tags
            #
            # In YARD, a docstring's free-form description can only appear before the
            # first `@tag`. Once the parser hits a tag, everything that follows
            # (until the next tag) is considered part of that tag's content.
            #
            # A description is optional.
            #
            # A segment is a part of the docstring. It is either the free-form
            # description or a YARD tag.
            #
            # The first segment never results in an offense.
            #
            # @param docstring [String] the raw docstring content
            #
            # @return [Array<Hash>] array of hashes with :from and :to tag names
            #
            def offending_transitions(docstring)
              lines = docstring.split("\n")
              transitions = []

              previous_segment_name = nil # nil means we are processing the first segment

              had_blank_line = true

              lines.each do |line|
                if line.strip.empty?
                  had_blank_line = true
                  next
                end

                # YARD tags begin at column 0 of the docstring. Indented @-leading
                # lines are tag continuation or @example/code content (e.g. an
                # instance variable like `@result`), not new tags.
                tag_name = line[/\A@(\S+)/, 1]

                if tag_name
                  if offending_transition?(previous_segment_name, had_blank_line, tag_name)
                    transitions << {from: previous_segment_name, to: tag_name}
                  end

                  previous_segment_name = tag_name
                elsif previous_segment_name.nil?
                  previous_segment_name = "description"
                end

                had_blank_line = false
              end

              transitions
            end

            # Whether a missing separator should be reported between the previous
            # segment and the current tag
            #
            # @param previous_segment_name [String, nil] the previous tag name, 'description', or nil
            # @param had_blank_line [Boolean] whether a blank line preceded the current tag
            # @param tag_name [String] the current tag name
            #
            # @return [Boolean] whether to report a missing separator
            def offending_transition?(previous_segment_name, had_blank_line, tag_name)
              # The first segment never results in an offense
              return false if previous_segment_name.nil?

              # If a blank line occurs between the previous segment and the current
              # tag there is no offense
              return false if had_blank_line

              # In a description->tag transition, exempt does not apply. This
              # transition is only an offense if the RequireAfterDescription option
              # is set.
              return require_after_description? if previous_segment_name == "description"

              return false if exempt.include?(tag_name)

              true
            end

            # @return [Array<String>] tag names that may follow without a blank line
            def exempt
              @exempt ||= config.validator_config("Tags/TagSeparator", "Exempt") ||
                Config.defaults["Exempt"]
            end

            # @return [Boolean] whether to require separator after description
            def require_after_description?
              @require_after_description ||= config.validator_config(
                "Tags/TagSeparator",
                "RequireAfterDescription"
              ) || false
            end
          end
        end
      end
    end
  end
end

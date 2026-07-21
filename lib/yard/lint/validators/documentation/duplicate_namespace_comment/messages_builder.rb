# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module DuplicateNamespaceComment
          # Builds messages for duplicate namespace comment offenses
          class MessagesBuilder
            # Maximum number of documented locations listed inline in the message
            MAX_LISTED_SITES = 5

            class << self
              # Build message for a namespace documented in multiple files
              # @param offense [Hash] offense data with :namespace, :sites and :conflict keys
              # @return [String] formatted message
              def call(offense)
                sites = Array(offense[:sites])
                listed = sites.first(MAX_LISTED_SITES).map { |site| relativize(site) }
                remainder = sites.size - listed.size
                located = listed.join(', ')
                located += " (+#{remainder} more)" if remainder.positive?

                differ = offense[:conflict] == 'differ' ? ' The docstrings differ, so content is lost.' : ''

                "Namespace `#{offense[:namespace]}` is documented in #{sites.size} files; " \
                  "YARD keeps only one docstring and discards the rest.#{differ} " \
                  "Documented at: #{located}. " \
                  'Consolidate the documentation into a single location.'
              end

              private

              # Shortens an absolute "path:line" site to a path relative to the working
              # directory for readability, leaving already-relative paths untouched.
              # @param site [String] a "path:line" location
              # @return [String] a display-friendly location
              def relativize(site)
                path, _, line = site.rpartition(':')
                return site if path.empty?

                relative = path.start_with?("#{Dir.pwd}/") ? path.sub("#{Dir.pwd}/", '') : path
                "#{relative}:#{line}"
              end
            end
          end
        end
      end
    end
  end
end

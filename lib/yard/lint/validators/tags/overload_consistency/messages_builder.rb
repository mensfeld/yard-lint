# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module OverloadConsistency
          # Builds human-readable messages for OverloadConsistency violations
          class MessagesBuilder
            class << self
              # Formats an overload consistency violation message
              # @param offense [Hash] offense details with :kind, :param and :signature keys
              # @return [String] formatted message
              def call(offense)
                overload = "Overload '#{offense[:signature]}'"

                case offense[:kind]
                when 'unknown_param'
                  "#{overload} documents @param '#{offense[:param]}', which is not in its signature"
                when 'undocumented_param'
                  "#{overload} has no @param for '#{offense[:param]}'"
                else
                  "#{overload} has no @return, while other overloads of this method have one"
                end
              end
            end
          end
        end
      end
    end
  end
end

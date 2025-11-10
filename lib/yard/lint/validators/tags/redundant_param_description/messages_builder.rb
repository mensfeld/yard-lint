# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module RedundantParamDescription
          # Builds human-readable messages for redundant parameter description violations
          class MessagesBuilder
            # Build message for a violation
            # @param offense [Hash] the offense data
            # @return [String] formatted message
            def self.call(offense)
              tag_name = offense[:tag_name]
              param_name = offense[:param_name]
              description = offense[:description]
              pattern_type = offense[:pattern_type]

              case pattern_type
              when 'article_param'
                "The @#{tag_name} description '#{description}' is redundant - " \
                "it just restates the parameter name. " \
                "Consider removing the description: @#{tag_name} #{param_name} [Type]"

              when 'possessive_param'
                "The @#{tag_name} description '#{description}' adds no meaningful information " \
                "beyond the parameter name. " \
                "Consider removing it or explaining the parameter's specific purpose."

              when 'type_restatement'
                "The @#{tag_name} description '#{description}' just repeats the type name. " \
                "Consider removing the description or explaining what makes this #{param_name} significant."

              when 'param_to_verb'
                "The @#{tag_name} description '#{description}' is too generic. " \
                "Consider removing it or explaining what the #{param_name} is used for in detail."

              when 'id_pattern'
                "The @#{tag_name} description '#{description}' is self-explanatory from the parameter name. " \
                "Consider removing the description: @#{tag_name} #{param_name} [Type]"

              when 'directional_date'
                "The @#{tag_name} description '#{description}' is redundant - " \
                "the parameter name already indicates this. " \
                "Consider removing the description or explaining the date's specific meaning."

              when 'type_generic'
                "The @#{tag_name} description '#{description}' just combines type and generic terms. " \
                "Consider removing it or providing specific details about this #{param_name}."

              else
                "The @#{tag_name} description '#{description}' appears redundant. " \
                "Consider providing a meaningful description or omitting it entirely."
              end
            end
          end
        end
      end
    end
  end
end

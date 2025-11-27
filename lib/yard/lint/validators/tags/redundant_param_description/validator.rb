# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module RedundantParamDescription
          # Validates that parameter descriptions are not redundant/meaningless
          class Validator < Validators::Base
            # Enable in-process execution
            in_process visibility: :public

            # Execute query for a single object during in-process execution.
            # Checks for redundant/meaningless parameter descriptions.
            # @param object [YARD::CodeObjects::Base] the code object to query
            # @param collector [Executor::ResultCollector] collector for output
            # @return [void]
            # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize
            def in_process_query(object, collector)
              return unless object.is_a?(YARD::CodeObjects::MethodObject)

              articles = config_articles
              generic_terms = config_generic_terms.map(&:downcase)
              connectors = config_low_value_connectors.map(&:downcase)
              low_value_verbs = config_low_value_verbs.map(&:downcase)
              max_words = config_max_redundant_words
              tags_to_check = config_checked_tags
              patterns = config_enabled_patterns

              object.docstring.tags.each do |tag|
                next unless tags_to_check.include?(tag.tag_name)
                next unless tag.name && tag.text && !tag.text.strip.empty?

                param_name = tag.name
                description = tag.text.strip.gsub(/\.$/, '')
                word_count = description.split.length
                type_name = tag.types&.first&.gsub(/[<>{}\[\],]/, '')&.strip

                next if word_count > max_words

                pattern_type = detect_pattern(
                  param_name, description, type_name, word_count,
                  articles, generic_terms, connectors, low_value_verbs, patterns
                )

                next unless pattern_type

                collector.puts "#{object.file}:#{object.line}: #{object.title}"
                collector.puts "#{tag.tag_name}|#{param_name}|#{tag.text.strip}|#{type_name || ''}|#{pattern_type}|#{word_count}"
              end
            end
            # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize

            private

            # Detect the type of redundant pattern
            # @param param_name [String] parameter name
            # @param description [String] description text
            # @param type_name [String, nil] type annotation
            # @param word_count [Integer] number of words in description
            # @param articles [Array<String>] article words
            # @param generic_terms [Array<String>] generic terms
            # @param connectors [Array<String>] low-value connectors
            # @param low_value_verbs [Array<String>] low-value verbs
            # @param patterns [Hash] enabled pattern flags
            # @return [String, nil] pattern type or nil
            # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize, Metrics/ParameterLists
            def detect_pattern(param_name, description, type_name, word_count, articles, generic_terms, connectors, low_value_verbs, patterns)
              desc_parts = description.split
              articles_re = /^(#{articles.join('|')})/i

              # ArticleParam pattern
              if patterns['ArticleParam'] && word_count <= 3 && desc_parts.length == 2
                if desc_parts[0].match?(articles_re) && desc_parts[1].downcase == param_name.downcase
                  return 'article_param'
                end
              end

              # PossessiveParam pattern
              if patterns['PossessiveParam'] && word_count <= 4 && desc_parts.length >= 3
                if desc_parts[0].match?(articles_re) && desc_parts[1].end_with?('s') &&
                   desc_parts[1].include?("'") && desc_parts[2].downcase == param_name.downcase
                  return 'possessive_param'
                end
              end

              # TypeRestatement pattern
              if patterns['TypeRestatement'] && type_name && word_count <= 2
                if description.downcase == type_name.downcase
                  return 'type_restatement'
                elsif word_count == 2
                  parts = description.split
                  if parts[0].downcase == type_name.downcase && generic_terms.include?(parts[1].downcase)
                    return 'type_restatement'
                  end
                end
              end

              # ParamToVerb pattern
              if patterns['ParamToVerb'] && word_count <= 4 && desc_parts.length == 3
                if desc_parts[0].downcase == param_name.downcase && desc_parts[1].downcase == 'to'
                  return 'param_to_verb'
                end
              end

              # IdPattern
              if patterns['IdPattern'] && word_count <= 6 && param_name =~ /_id$|_uuid$|_identifier$/
                if description =~ /^(ID|Unique identifier|Identifier)\s+(of|for)\s+/i
                  return 'id_pattern'
                end
              end

              # DirectionalDate pattern
              if patterns['DirectionalDate'] && word_count <= 4 && param_name =~ /^(from|to|till|until)$/
                if desc_parts.length == 3 && desc_parts[0].downcase == param_name.downcase && desc_parts[1].downcase == 'this'
                  return 'directional_date'
                end
              end

              # TypeGeneric pattern
              if patterns['TypeGeneric'] && type_name && word_count <= 5 && desc_parts.length >= 2
                if desc_parts[0].downcase == type_name.downcase && generic_terms.include?(desc_parts[1].downcase)
                  return 'type_generic'
                end
              end

              # ArticleParamPhrase pattern: "The action being performed"
              if patterns['ArticleParamPhrase'] && word_count >= 3 && desc_parts.length >= 3
                if desc_parts[0].match?(articles_re) &&
                   desc_parts[1].downcase == param_name.downcase &&
                   connectors.include?(desc_parts[2].downcase) &&
                   (desc_parts.length == 3 || low_value_verbs.include?(desc_parts[3].downcase))
                  return 'article_param_phrase'
                end
              end

              nil
            end
            # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize, Metrics/ParameterLists

            private

            # @return [Array<String>] configured articles to check
            def config_articles
              config_or_default('Articles')
            end

            # @return [Array<String>] configured generic terms to check
            def config_generic_terms
              config_or_default('GenericTerms')
            end

            # @return [Array<String>] configured low-value connectors
            def config_low_value_connectors
              config_or_default('LowValueConnectors')
            end

            # @return [Array<String>] configured low-value verbs
            def config_low_value_verbs
              config_or_default('LowValueVerbs')
            end

            # @return [Integer] maximum word count for redundant descriptions
            def config_max_redundant_words
              config_or_default('MaxRedundantWords')
            end

            # @return [Array<String>] tags to check for redundant descriptions
            def config_checked_tags
              config_or_default('CheckedTags')
            end

            # @return [Hash] enabled pattern detection flags
            def config_enabled_patterns
              config_or_default('EnabledPatterns')
            end
          end
        end
      end
    end
  end
end

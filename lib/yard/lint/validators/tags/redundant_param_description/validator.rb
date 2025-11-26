# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module RedundantParamDescription
          # Validates that parameter descriptions are not redundant/meaningless
          class Validator < Validators::Base
            # YARD query to detect redundant parameter descriptions
            # @return [String] YARD Ruby query code
            def query
              articles = config_articles.join('|')
              generic_terms = config_generic_terms.join('|')
              max_words = config_max_redundant_words
              checked_tags = config_checked_tags
              patterns = config_enabled_patterns

              # Build query as single line for shell compatibility
              query_body = 'if object.is_a?(YARD::CodeObjects::MethodObject); ' \
                "object.docstring.tags.select { |tag| #{checked_tags.inspect}.include?(tag.tag_name) }.each do |tag|; " \
                'next unless tag.name && tag.text && !tag.text.strip.empty?; ' \
                'param_name = tag.name; ' \
                'description = tag.text.strip.gsub(/\\.$/, ""); ' \
                'word_count = description.split.length; ' \
                'type_name = tag.types&.first&.gsub(/[<>{}\\[\\],]/, "")&.strip; ' \
                "next if word_count > #{max_words}; " \
                'pattern_type = nil; ' \
                "if #{patterns['ArticleParam']} && word_count <= 3; " \
                "articles_re = /^(#{articles})/i; " \
                'desc_parts = description.split; ' \
                'if desc_parts.length == 2 && desc_parts[0].match?(articles_re) && desc_parts[1].downcase == param_name.downcase; ' \
                'pattern_type = "article_param"; ' \
                'end; ' \
                'end; ' \
                "if pattern_type.nil? && #{patterns['PossessiveParam']} && word_count <= 4; " \
                'desc_parts = description.split; ' \
                'if desc_parts.length >= 3; ' \
                "articles_re = /^(#{articles})/i; " \
                'if desc_parts[0].match?(articles_re) && desc_parts[1].end_with?("s") && desc_parts[1].include?(39.chr) && desc_parts[2].downcase == param_name.downcase; ' \
                'pattern_type = "possessive_param"; ' \
                'end; ' \
                'end; ' \
                'end; ' \
                "if pattern_type.nil? && #{patterns['TypeRestatement']} && type_name && word_count <= 2; " \
                "generic_terms_arr = [\"#{generic_terms.gsub('|', '\", \"')}\"].map(&:downcase); " \
                'if description.downcase == type_name.downcase; ' \
                'pattern_type = "type_restatement"; ' \
                'elsif word_count == 2; ' \
                'parts = description.split; ' \
                'if parts[0].downcase == type_name.downcase && generic_terms_arr.include?(parts[1].downcase); ' \
                'pattern_type = "type_restatement"; ' \
                'end; ' \
                'end; ' \
                'end; ' \
                "if pattern_type.nil? && #{patterns['ParamToVerb']} && word_count <= 4; " \
                'parts = description.split; ' \
                'if parts.length == 3 && parts[0].downcase == param_name.downcase && parts[1].downcase == "to"; ' \
                'pattern_type = "param_to_verb"; ' \
                'end; ' \
                'end; ' \
                "if pattern_type.nil? && #{patterns['IdPattern']} && word_count <= 6; " \
                'if param_name =~ /_id$|_uuid$|_identifier$/; ' \
                'if description =~ /^(ID|Unique identifier|Identifier)\\s+(of|for)\\s+/i; ' \
                'pattern_type = "id_pattern"; ' \
                'end; ' \
                'end; ' \
                'end; ' \
                "if pattern_type.nil? && #{patterns['DirectionalDate']} && word_count <= 4; " \
                'if param_name =~ /^(from|to|till|until)$/; ' \
                'parts = description.split; ' \
                'if parts.length == 3 && parts[0].downcase == param_name.downcase && parts[1].downcase == "this"; ' \
                'pattern_type = "directional_date"; ' \
                'end; ' \
                'end; ' \
                'end; ' \
                "if pattern_type.nil? && #{patterns['TypeGeneric']} && type_name && word_count <= 5; " \
                "generic_terms_arr = [\"#{generic_terms.gsub('|', '\", \"')}\"].map(&:downcase); " \
                'parts = description.split; ' \
                'if parts.length >= 2 && parts[0].downcase == type_name.downcase && generic_terms_arr.include?(parts[1].downcase); ' \
                'pattern_type = "type_generic"; ' \
                'end; ' \
                'end; ' \
                'if pattern_type; ' \
                'puts object.file + ":" + object.line.to_s + ": " + object.title; ' \
                'puts tag.tag_name + "|" + param_name + "|" + tag.text.strip + "|" + (type_name || "") + "|" + pattern_type + "|" + word_count.to_s; ' \
                'end; ' \
                'end; ' \
                'end; ' \
                'false'

              # Wrap in single quotes like other validators do
              "'#{query_body}'"
            end

            # Builds and executes the YARD command
            # @param dir [String] the directory containing the .yardoc database
            # @param file_list_path [String] path to file containing list of files to analyze
            # @return [Hash] command output with stdout, stderr, exit_code
            def yard_cmd(dir, file_list_path)
              # Create a temporary script file to avoid shell escaping issues
              require 'tempfile'

              script = Tempfile.new(['yard_lint_query', '.sh'])
              script.write("#!/bin/sh\n")
              # Write query to a variable - since query already has outer single quotes, just assign it
              script.write("QUERY=#{query}\n")
              script.write("cat #{Shellwords.escape(file_list_path)} | xargs yard list #{shell_arguments} --query \"$QUERY\" -q -b #{Shellwords.escape(dir)}\n")
              script.chmod(0o755)
              script.close

              result = shell(script.path)
              script.unlink
              result
            end

            private

            # @return [Array<String>] configured articles to check
            def config_articles
              config_or_default('Articles')
            end

            # @return [Array<String>] configured generic terms to check
            def config_generic_terms
              config_or_default('GenericTerms')
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

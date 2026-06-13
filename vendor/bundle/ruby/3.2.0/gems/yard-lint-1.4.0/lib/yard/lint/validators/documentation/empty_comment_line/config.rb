# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module EmptyCommentLine
          # Configuration for EmptyCommentLine validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :empty_comment_line
            self.defaults = {
              'Enabled' => true,
              'Severity' => 'convention',
              'EnabledPatterns' => {
                'Leading' => true,
                'Trailing' => true
              }
            }.freeze
          end
        end
      end
    end
  end
end

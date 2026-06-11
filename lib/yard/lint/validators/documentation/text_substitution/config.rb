# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Documentation
        module TextSubstitution
          # Configuration for the TextSubstitution validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :text_substitution
            self.defaults = {
              'Enabled' => false,
              'Severity' => 'warning',
              'Substitutions' => {
                "—" => '-', # em-dash (—)
                "–" => '-'  # en-dash (–)
              }
            }.freeze
          end
        end
      end
    end
  end
end

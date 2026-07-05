# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module TagSeparator
          # Configuration for TagSeparator validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :tag_separator
            self.defaults = {
              "Enabled" => false,
              "Severity" => "convention",
              "Exempt" => [],
              "RequireAfterDescription" => false
            }.freeze
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module RedundantParamDescription
          # Configuration for RedundantParamDescription validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :redundant_param_description
            self.defaults = {
              'Enabled' => true,
              'Severity' => 'convention',
              'CheckedTags' => %w[param option],
              'Articles' => %w[The the A a An an],
              'MaxRedundantWords' => 6,
              'GenericTerms' => %w[object instance value data item element],
              'EnabledPatterns' => {
                'ArticleParam' => true,
                'PossessiveParam' => true,
                'TypeRestatement' => true,
                'ParamToVerb' => true,
                'IdPattern' => true,
                'DirectionalDate' => true,
                'TypeGeneric' => true
              }
            }.freeze
          end
        end
      end
    end
  end
end

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
              'LowValueConnectors' => %w[being to that which for],
              'LowValueVerbs' => %w[
                perform performed performing
                process processed processing
                use used using
                handle handled handling
                act acted acting
                pass passed passing
                invoke invoked invoking
                call called calling
                execute executed executing
                run running
              ],
              'EnabledPatterns' => {
                'ArticleParam' => true,
                'PossessiveParam' => true,
                'TypeRestatement' => true,
                'ParamToVerb' => true,
                'IdPattern' => true,
                'DirectionalDate' => true,
                'TypeGeneric' => true,
                'ArticleParamPhrase' => true
              }
            }.freeze
          end
        end
      end
    end
  end
end

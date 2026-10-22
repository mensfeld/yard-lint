# frozen_string_literal: true

module Yard
  module Lint
    module Contractable
      # Representation of a single validation rule
      Rule = Struct.new(:path, :type, :validator)
    end
  end
end

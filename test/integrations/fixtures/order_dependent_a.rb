# frozen_string_literal: true

class OrderCore
  alias_method :run_alias, :run
  alias go run
end

module OrderUtil
  module_function :ready?, :work
end

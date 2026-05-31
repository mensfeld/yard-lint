# frozen_string_literal: true

class InvalidTypesMessages
  # @param body [anything] lowercase = not a valid constant name
  # @return [wrong_return_type] another invalid type
  def call(body)
    body
  end

  # @param value [bad_type] only one bad type
  def process(value)
    value
  end
end

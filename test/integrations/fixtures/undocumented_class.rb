# frozen_string_literal: true

class UndocumentedClass
  def method_one
    'test'
  end
end

module UndocumentedModule
  class NestedClass
    def nested_method
      'nested'
    end
  end
end

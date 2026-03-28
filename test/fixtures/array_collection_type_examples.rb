# frozen_string_literal: true

# Fixture for testing Array collection type style enforcement
# YARD supports both long and short forms for Array collections:
#   Long:  Array<String>, Array(String, Integer)
#   Short: <String>, (String, Integer)
# See: https://github.com/mensfeld/yard-lint/issues/114

# --- Long style: Array<...> (angle brackets with prefix) ---

class ArrayLongAngleBrackets
  # @param items [Array<String>] list of items
  # @return [Array<Integer>] counts
  def basic(items)
    items.map(&:size)
  end

  # @param matrix [Array<Array<Integer>>] nested array
  # @return [void]
  def nested(matrix)
  end

  # @param items [Array<String>] list of items
  # @param opts [Hash{Symbol => String}] options
  # @return [Array<Boolean>] results
  def mixed_with_hash(items, opts)
    []
  end
end

# --- Long style: Array(...) (parentheses with prefix) ---

class ArrayLongParens
  # @param pair [Array(String, Integer)] a key-value pair
  # @return [Array(Symbol, String, Integer)] a triple
  def basic(pair)
    [:ok, pair[0], pair[1]]
  end

  # @param data [Array(Boolean, String, Integer, Float)] a four-element tuple
  # @return [void]
  def four_elements(data)
  end

  # @return [Array(String, nil)] name or nil pair
  def with_nil_element
  end
end

# --- Short style: <...> (angle brackets without prefix) ---

class ArrayShortAngleBrackets
  # @param items [<String>] list of items
  # @return [<Integer>] counts
  def basic(items)
    items.map(&:size)
  end

  # @param items [<String, Symbol>] list of items
  # @return [void]
  def multiple_types(items)
  end
end

# --- Short style: (...) (parentheses without prefix) ---

class ArrayShortParens
  # @param pair [(String, Integer)] a key-value pair
  # @return [(Symbol, String, Integer)] a triple
  def basic(pair)
    [:ok, pair[0], pair[1]]
  end

  # @return [(Boolean, String)] a result pair
  def two_element_tuple
  end

  # @return [(String, Integer, Symbol, Boolean)] a four-element tuple
  def four_element_tuple
  end
end

# --- Short tuple or nil ---

class ArrayShortTupleOrNil
  # @return [(String, Integer), nil] a pair or nil
  def maybe_pair
  end
end

# --- Long tuple or nil ---

class ArrayLongTupleOrNil
  # @return [Array(String, Integer), nil] a pair or nil
  def maybe_pair
  end
end

# --- In @param tags ---

class ArrayInParams
  # @param items [<String>] short style in param
  # @param pair [(Integer, String)] short tuple in param
  # @return [void]
  def short_style_params(items, pair)
  end

  # @param items [Array<String>] long style in param
  # @param pair [Array(Integer, String)] long tuple in param
  # @return [void]
  def long_style_params(items, pair)
  end
end

# --- In @return tags ---

class ArrayInReturn
  # @return [<String>] short style return
  def short_angle
  end

  # @return [(String, Integer)] short tuple return
  def short_tuple
  end

  # @return [Array<String>] long style return
  def long_angle
  end

  # @return [Array(String, Integer)] long tuple return
  def long_tuple
  end
end

# --- In @yieldreturn tags ---

class ArrayInYieldreturn
  # @yieldreturn [<String>] short style
  def short_angle
    yield
  end

  # @yieldreturn [(String, Integer)] short tuple style
  def short_tuple
    yield
  end

  # @yieldreturn [Array<String>] long style
  def long_angle
    yield
  end

  # @yieldreturn [Array(String, Integer)] long tuple style
  def long_tuple
    yield
  end
end

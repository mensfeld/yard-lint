# frozen_string_literal: true

# Fixture for testing tuple (fixed-length array) type notation
# YARD supports tuples as documented at https://yardoc.org/types.html
# See: https://github.com/mensfeld/yard-lint/issues/113

class TupleTypes
  # @return [(String, Integer)] a simple tuple
  def simple_tuple
  end

  # @return [(String, Integer), nil] a tuple or nil
  def tuple_or_nil
  end

  # @param data [Array<Integer>] buffered input bytes
  # @return [(SDN::Message::ILT2::MasterControl, Integer), nil]
  def namespaced_tuple(data)
  end

  # @param pair [(String, Integer)] a key-value pair
  # @return [void]
  def tuple_param(pair)
  end

  # @return [(Symbol, String, Integer)] a three-element tuple
  def triple_tuple
  end
end

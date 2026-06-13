# frozen_string_literal: true

# Methods using custom collection classes whose names contain Hash/Array.
class CollectionTypeCustom
  # Uses a custom hash-like class.
  # @param map [MyHash<String, Integer>] a custom map
  # @return [void]
  def custom_hash(map)
    map
  end

  # Uses a custom array-like class.
  # @param bytes [ByteArray<Integer>] a custom byte array
  # @return [void]
  def custom_array(bytes)
    bytes
  end

  # Uses a genuine short-style Hash that should be long style.
  # @return [Hash<Symbol, String>] a real hash in short style
  def real_hash
    {}
  end
end

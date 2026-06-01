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

  # Valid: nested Hash types must not produce false positives.
  # These cover the "complex hash values" case from issue #151/#152.
  # @return [Hash{String => Hash{Symbol => Array<String>}}] two-level nested hash
  def nested_hash_two_levels; end

  # @return [Hash{Symbol => Hash{String => Hash{Integer => String}}}] three-level nested hash
  def nested_hash_three_levels; end

  # @param opts [Hash{Symbol => Array<Hash{String => Integer}>}] hash inside array inside hash
  def hash_in_array_in_hash(opts); end

  # Valid: simple one-level hash must not be flagged.
  # @return [Hash{String => Integer}] simple hash
  def simple_hash; end

  # Invalid: bad type nested inside a hash value should still be caught.
  # @return [Hash{String => bad_nested_type}] hash with invalid value type
  def hash_with_invalid_value; end
end

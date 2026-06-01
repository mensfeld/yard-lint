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

  # Valid: YARD pseudo-types used as hash values must not produce false positives.
  # @return [Hash{String => undefined}] undefined is a YARD pseudo-type
  def hash_with_undefined_value; end

  # @return [Hash{String => unspecified}] unspecified is a YARD pseudo-type
  def hash_with_unspecified_value; end

  # @return [Hash{String => unknown}] unknown is a YARD pseudo-type
  def hash_with_unknown_value; end

  # @return [Hash{String => Array<Hash{String => undefined}>}] nested with undefined
  def hash_nested_with_undefined; end

  # Valid: undefined as a standalone return type
  # @return [undefined] raw pseudo-type (not in hash)
  def standalone_undefined; end
end

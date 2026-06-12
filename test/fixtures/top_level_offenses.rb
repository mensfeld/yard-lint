# frozen_string_literal: true

# Fixture for parser location-regex tests. All offenses here live on
# top-level (root namespace) methods or constants, whose YARD titles
# (#method_name, CONST_NAME) carry no Class#method separator.

# Adds two numbers together
# @param first [Integer] first number
def top_level_partially_documented(first, second)
  first + second
end

# Returns a label
# @return [strng] mistyped lowercase type
def top_level_invalid_type
  'label'
end

# Maximum number of retries
# @return [strng] mistyped lowercase type
TOP_LEVEL_BAD_CONST = 5

# Builds a label
# @return [String] the label
# @param value [String] input value
def top_level_wrong_tag_order(value)
  value
end

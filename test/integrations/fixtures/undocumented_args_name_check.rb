# frozen_string_literal: true

# Fixtures for Documentation/UndocumentedMethodArguments BUG-041 options
# (CheckParameterNames and SkipFullyUndocumented).
class UndocumentedArgsNameCheck
  def fully_undocumented(item); end

  # Count matches (1 tag, 1 param) but the @param name is wrong, so `item`
  # is not actually documented.
  # @param wrong [String] misnamed
  def misnamed_param(item); end

  # Every parameter documented by name.
  # @param item [String] the item
  # @param count [Integer] how many
  def all_documented(item, count); end

  # Keyword parameter documented (param is `name:`, tag is `name`).
  # @param name [String] the name
  def keyword_documented(name:); end

  # Only one of two parameters documented (caught by the count check too).
  # @param a [Integer] first
  def partially_documented(a, b); end
end

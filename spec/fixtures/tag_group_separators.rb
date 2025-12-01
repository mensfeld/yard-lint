# frozen_string_literal: true

# Test fixtures for TagGroupSeparator validator

# Example class with various tag group separation scenarios
class TagGroupSeparatorFixtures
  # Bad: Missing separator between param and return
  #
  # @param organization_id [String] the organization ID
  # @param id [String] the pet ID
  # @return [Pet] the pet object
  def missing_param_return_separator(organization_id, id); end

  # Bad: Missing separator between return and raise
  #
  # @param id [String] the ID
  #
  # @return [Object] the result
  # @raise [ArgumentError] when ID is invalid
  def missing_return_raise_separator(id); end

  # Bad: Multiple missing separators
  #
  # @param id [String] the ID
  # @return [Object] the result
  # @raise [ArgumentError] when invalid
  # @example
  #   example_usage
  def multiple_missing_separators(id); end

  # Good: All separators present
  #
  # @param organization_id [String] the organization ID
  # @param id [String] the pet ID
  #
  # @return [Pet] the pet object
  def proper_separators(organization_id, id); end

  # Good: Same group tags don't need separators
  #
  # @param id [String] the ID
  # @param name [String] the name
  # @option opts [Boolean] :force force operation
  # @option opts [Integer] :limit maximum items
  def same_group_tags(id, name, opts = {}); end

  # Good: Single tag group only
  #
  # @param id [String] the ID
  def single_group(id); end

  # Good: No tags at all
  #
  # Just a description without any tags.
  def no_tags; end

  # Bad: Description to param without separator (when RequireAfterDescription is true)
  # This method processes data
  # @param data [String] the data
  def description_to_param_no_separator(data); end

  # Good: Description to param with separator
  #
  # This method processes data
  #
  # @param data [String] the data
  def description_to_param_with_separator(data); end

  # Good: Complex example with all separators
  #
  # Process the given input with various options.
  #
  # @param input [String] the input to process
  # @param options [Hash] processing options
  # @option options [Boolean] :validate whether to validate
  # @option options [Integer] :limit max items to process
  #
  # @yield [chunk] yields each processed chunk
  # @yieldparam chunk [String] the processed chunk
  # @yieldreturn [Boolean] whether to continue
  #
  # @return [Array] processed results
  #
  # @raise [ArgumentError] when input is invalid
  # @raise [ProcessingError] when processing fails
  #
  # @example Basic usage
  #   process_input("data")
  #
  # @see OtherClass#related_method
  # @note This method is experimental
  def complex_with_all_separators(input, options = {})
    yield if block_given?
  end
end

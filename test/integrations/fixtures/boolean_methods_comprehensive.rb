# frozen_string_literal: true

# Example class demonstrating boolean method documentation patterns
class BooleanMethodsExample
  # Properly documented boolean method with @return [Boolean]
  # @param value [Object] value to check
  # @return [Boolean] true if value is present
  def present?(value)
    !value.nil? && value != ''
  end

  # Boolean method without @return tag (should trigger UndocumentedBooleanMethods)
  # @param value [Object] value to check
  def blank?(value)
    value.nil? || value == ''
  end

  # Boolean method with non-Boolean return type (should trigger warning)
  # @param value [String] value to check
  # @return [String] returns 'yes' or 'no'
  def active?(value)
    value == 'active' ? 'yes' : 'no'
  end

  # Boolean method with Boolean return properly documented
  # @return [Boolean] true if record is valid
  def valid?
    true
  end

  # Boolean method completely undocumented (should trigger multiple validators)
  def enabled?
    true
  end

  # Predicate method ending with ? but not returning boolean conceptually
  # @param key [Symbol] key to lookup
  # @return [Object, nil] value if found, nil otherwise
  def key?(key)
    @data[key]
  end

  # Boolean method with complex return documentation
  # @param name [String] name to check
  # @return [Boolean] true if name exists in the database, false otherwise
  def exists?(name)
    @names.include?(name)
  end

  # Boolean method with TrueClass/FalseClass return (alternative documentation)
  # @param id [Integer] record ID
  # @return [TrueClass, FalseClass] whether record is persisted
  def persisted?(id)
    id.positive?
  end

  # Boolean method with only @return true/false (missing type)
  # @param value [Integer] value to check
  # @return true if positive, false otherwise
  def positive?(value)
    value.positive?
  end

  # Multiple boolean methods in a row
  # @return [Boolean] whether empty
  def empty?
    @items.empty?
  end

  # @return [Boolean] whether any items exist
  def any?
    !@items.empty?
  end

  # Undocumented boolean method (should trigger)
  def none?
    @items.empty?
  end

  # Boolean method with wrong tag order
  # @return [Boolean] whether included
  # @param item [Object] item to check
  def include?(item)
    @items.include?(item)
  end

  # Class-level boolean method
  # @param name [String] class name
  # @return [Boolean] whether class is defined
  def self.defined?(name)
    const_defined?(name)
  end

  # Private boolean method (documented)
  # @param value [Object] value to check
  # @return [Boolean] whether value is truthy
  def truthy?(value)
    !!value
  end
  private :truthy?

  # Private boolean method (undocumented)
  def falsey?(value)
    !value
  end
  private :falsey?

  # Boolean method with yield
  # @param items [Array] items to check
  # @yield [Object] gives each item
  # @return [Boolean] whether block returned true for all items
  def all?(items, &)
    items.all?(&)
  end

  # Edge case: method name contains ? but doesn't end with it
  # @param input [String] input string
  # @return [String] processed string
  def process_question_mark(input)
    input.delete('?')
  end

  # Boolean method with see tag
  # @see #present?
  # @param value [Object] value to check
  # @return [Boolean] opposite of present?
  def absent?(value)
    !present?(value)
  end
end

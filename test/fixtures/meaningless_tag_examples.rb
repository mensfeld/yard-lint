# frozen_string_literal: true

# Test fixture for MeaninglessTag validator
# Contains both valid and invalid tag placements

# Valid: @param tag on a method
class ValidMethodWithParam
  # Process user data
  # @param name [String] user name
  # @return [String] processed name
  def process(name)
    name.upcase
  end
end

# Invalid: @param tag on a class
# @param invalid [String] this doesn't make sense on a class
class InvalidClassWithParam
  def do_something
    'something'
  end
end

# Invalid: @option tag on a module
# @option opts [String] :key This doesn't make sense on a module
module InvalidModuleWithOption
  def self.run
    'running'
  end
end

# Invalid: @param tag on a constant
# @param wrong [Integer] constants can't have params
INVALID_CONSTANT_WITH_PARAM = 42

# Valid: Method with @option tag
class ValidMethodWithOption
  # Configure settings
  # @param opts [Hash] configuration options
  # @option opts [String] :name User name
  # @option opts [Integer] :age User age
  # @return [Hash] validated options
  def configure(opts = {})
    opts
  end
end

# Invalid: Multiple meaningless tags on a class
# @param first [String] first param
# @param second [Integer] second param
# @option opts [Boolean] :enabled Whether enabled
class InvalidClassWithMultipleTags
  # This class has meaningless @param and @option tags
  def initialize
    @data = {}
  end
end

# Valid: Nested class with valid method tags
class OuterClass
  # Inner class without meaningless tags
  class InnerClass
    # Valid method with param
    # @param value [Object] the value
    # @return [Object] the value
    def store(value)
      @value = value
    end
  end
end

# Invalid: Module constant with @param
module SomeModule
  # @param wrong [String] this is wrong
  CONST_WITH_PARAM = 'value'
end

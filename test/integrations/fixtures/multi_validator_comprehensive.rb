# frozen_string_literal: true

# Comprehensive multi-validator test fixture
# This file intentionally contains multiple documentation issues
# to test validator interactions and ensure they work correctly together

# Scenario 1: Basic combination (3 validators)
# - UndocumentedMethodArguments (missing @param)
# - Tags/Order (wrong tag order)
# - Warnings/UnknownParameterName (@param for non-existent param)
class BasicCombo
  # Test method with multiple tag issues
  # @return [String] result
  # @param name [String] user name
  # @param wrong_name [String] this parameter doesn't exist
  def basic_combo_method(name)
    name.to_s
  end
end

# Scenario 2: Boolean method issues (3 validators)
# - UndocumentedBooleanMethods (no @return for boolean method)
# - Tags/ApiTags (missing @api tag when enabled)
# - Tags/Order (wrong tag order)
class BooleanMethodIssues
  # Check if user is valid
  # @param user [User] user object
  # @see User#validate
  # @example
  #   valid?(user) #=> true
  def valid?(user)
    !user.nil?
  end
end

# Scenario 3: Hash options complexity (4 validators)
# - Tags/OptionTags (missing @option tags)
# - UndocumentedMethodArguments (missing @param for hash)
# - Tags/TypeSyntax (malformed type syntax)
# - Warnings/UnknownParameterName (@param for wrong parameter)
class HashOptionsComplexity
  # Process user data with options
  # @param wrong_param [Hash<] this is wrong
  # @return [Hash] processed data
  def process(opts = {})
    opts[:name] = opts[:name].to_s
    opts[:age] = opts[:age].to_i
    opts
  end
end

# Scenario 4: Abstract method problems (4 validators)
# - Semantic/AbstractMethods (@abstract but has implementation)
# - UndocumentedMethodArguments (missing @param)
# - Tags/Order (wrong tag order)
# - Warnings/InvalidDirectiveFormat (malformed directive)
class AbstractMethodProblems
  # @return [String] result
  # @abstract
  # @!macro [attach] test
  #   Invalid macro syntax here
  # @param data [String] input data
  def abstract_with_impl(data)
    data.to_s # This should not have implementation
  end
end

# Scenario 5: Kitchen sink method (7+ validators)
# - UndocumentedObjects (class not documented)
# - UndocumentedMethodArguments (multiple missing @param)
# - UndocumentedBooleanMethods (boolean without @return)
# - Tags/Order (completely wrong order)
# - Tags/TypeSyntax (multiple syntax errors)
# - Warnings/DuplicatedParameterName (duplicate @param)
# - Warnings/UnknownParameterName (unknown params)
# - Tags/InvalidTypes (invalid type definitions)
class KitchenSinkMethod
  # @see Something
  # @raise [Error] when fails
  # @param age [InvalidType] should be Integer
  # @option options [Array<>] empty generic error
  # @param name [String] user name
  # @param name [String] duplicate param
  # @example
  #   kitchen_sink?('test', 25)
  # @param wrong [String] doesn't exist
  # @return [String] some return value
  # @param options [Hash{Symbol =>] unclosed hash
  def kitchen_sink?(name, age, options = {}, *args, **kwargs, &block)
    name && age && options && args && kwargs && block
  end
end

# Scenario 6: Type validation combo (2 validators)
# - Tags/TypeSyntax (malformed syntax)
# - Tags/InvalidTypes (invalid type names)
class TypeValidationCombo
  # Method with both type syntax and invalid type errors
  # @param data [Array<] unclosed bracket
  # @param value [NonExistentClass] invalid type
  # @return [Hash{Symbol] malformed hash
  def type_errors(data, value)
    { data: data, value: value }
  end
end

# Scenario 7: All warnings together (4 validators)
# - Warnings/UnknownTag (unknown tag)
# - Warnings/InvalidTagFormat (malformed tag)
# - Warnings/DuplicatedParameterName (duplicate)
# - Warnings/UnknownParameterName (unknown param)
class AllWarningsTogether
  # Method with all warning validator issues
  # @unknown_tag This tag doesn't exist
  # @param name user name (missing type)
  # @param name [String] duplicate
  # @param wrong [String] doesn't exist
  # @return [String] result
  def all_warnings(name)
    name.to_s
  end
end

# Scenario 8: Real-world DSL pattern (5 validators)
# - UndocumentedMethodArguments (missing params)
# - Tags/Order (wrong order)
# - Tags/TypeSyntax (type errors)
# - Tags/OptionTags (missing @option)
# - Warnings/UnknownParameterName (wrong params)
class RealWorldDSL
  # @return [void] description after return
  # @param name [String] validator name
  # @example
  #   validate :email, format: /regex/
  # @param wrong_param [Array<>] doesn't exist
  # @option opts [String] :format Format validator
  def validate(field, opts = {})
    # DSL-style validator definition
    @validators ||= []
    @validators << { field: field, opts: opts }
  end
end

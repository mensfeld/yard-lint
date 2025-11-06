# frozen_string_literal: true

# Example class with various attribute accessors
class AttributeMethodsExample
  # Documented attribute reader
  # @!attribute [r] name
  #   @return [String] the name
  attr_reader :name

  # Undocumented attribute reader
  attr_reader :age

  # Documented attribute writer
  # @!attribute [w] email
  #   @param value [String] the email address
  attr_writer :email

  # Undocumented attribute writer
  attr_writer :phone

  # Documented attribute accessor
  # @!attribute [rw] address
  #   @return [String] the address
  attr_accessor :address

  # Undocumented attribute accessor
  attr_accessor :city

  # Multiple undocumented attributes
  attr_reader :country, :postal_code
  attr_accessor :verified, :active

  # @param name [String] the name
  # @param age [Integer] the age
  def initialize(name, age)
    @name = name
    @age = age
  end

  # Regular method for comparison
  # @return [String] full info
  def info
    "#{@name} (#{@age})"
  end

  # Undocumented regular method
  def status
    @active ? 'active' : 'inactive'
  end
end

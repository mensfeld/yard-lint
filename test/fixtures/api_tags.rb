# frozen_string_literal: true

# Service with API tags for testing
class ApiService
  # Public API method - should have @api public
  # @param name [String] user name
  # @return [Hash] user data
  def public_method(name)
    { name: name }
  end

  # Private API method with correct tag
  # @api private
  # @param secret [String] secret key
  # @return [String] encrypted value
  def private_method(secret)
    "encrypted_#{secret}"
  end

  # Internal method without @api tag
  # @param _data [Hash] internal data
  # @return [Boolean] success
  def internal_method(_data)
    true
  end
end

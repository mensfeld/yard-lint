# frozen_string_literal: true

# Fixture for testing @option tag detection
class OptionTagsExample
  # Method with options param but no @option tags (should be flagged)
  # @param name [String] the name
  # @param options [Hash] the options
  # @return [String] formatted string
  def create_with_options(name, options = {})
    "#{name}: #{options.inspect}"
  end

  # Method with opts param but no @option tags (should be flagged)
  # @param value [Integer] the value
  # @param opts [Hash] optional settings
  # @return [Integer] result
  def process_with_opts(value, opts = {})
    value + (opts[:offset] || 0)
  end

  # Method with kwargs but no @option tags (should be flagged)
  # @param first_name [String] the first name
  # @param last_name [String] the last name
  # @param kwargs [Hash] additional options
  # @return [String] formatted name
  def format_name(first_name, last_name, **kwargs)
    "#{first_name} #{last_name}"
  end

  # Method with options AND proper @option tags (should NOT be flagged)
  # @param name [String] the user name
  # @param options [Hash] creation options
  # @option options [String] :email the email address
  # @option options [Integer] :age the user age
  # @return [Hash] user data
  def create_user(name, options = {})
    { name: name }.merge(options)
  end
end

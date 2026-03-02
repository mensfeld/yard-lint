# frozen_string_literal: true

# Service with option parameters
class OptionService
  # Method with options parameter but no @option tags
  # @param name [String] user name
  # @param options [Hash] configuration options
  # @return [Hash] result
  def create_with_options(name, options)
    { name: name, options: options }
  end

  # Method with opts parameter but no @option tags
  # @param data [Hash] data
  # @param opts [Hash] options
  # @return [Array] results
  def process_with_opts(data, opts)
    [data, opts]
  end

  # Method with options parameter AND @option tags (correct)
  # @param name [String] user name
  # @param options [Hash] configuration options
  # @option options [String] :email User email address
  # @option options [Integer] :age User age
  # @return [Hash] user data
  def create_user(name, options = {})
    { name: name, email: options[:email], age: options[:age] }
  end

  # Method with kwargs parameter but no @option tags
  # @param name [String] name
  # @param kwargs [Hash] keyword arguments
  # @return [String] result
  def format_name(name, kwargs)
    "#{name} - #{kwargs}"
  end
end

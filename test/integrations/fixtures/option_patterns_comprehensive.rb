# frozen_string_literal: true

# Example class demonstrating various @option tag patterns and edge cases
class OptionPatternsExample
  # Method with properly documented hash options
  # @param config [Hash] configuration hash
  # @option config [String] :name the name value
  # @option config [Integer] :timeout the timeout in seconds
  # @option config [Boolean] :enabled whether feature is enabled
  # @return [Hash] processed configuration
  def valid_options(config)
    config
  end

  # Method with missing @option tags (has Hash param but no options documented)
  # @param settings [Hash] settings hash
  # @return [Hash] processed settings
  def missing_options(settings)
    settings
  end

  # Method with @option but no corresponding Hash parameter
  # @param value [String] a string value (not a hash!)
  # @option value [String] :key this should trigger warning - value is not a Hash
  # @return [String] processed value
  def options_for_non_hash(value)
    value
  end

  # Method with nested option patterns
  # @param config [Hash] configuration hash
  # @option config [Hash] :database database settings
  # @option config [String] :database.host the database host
  # @option config [Integer] :database.port the database port
  # @option config [Hash] :cache cache settings
  # @option config [String] :cache.type cache type (redis/memcached)
  # @return [Hash] processed configuration
  def nested_options(config)
    config
  end

  # Method with options containing special characters
  # @param opts [Hash] options hash
  # @option opts [String] :api_key the API key
  # @option opts [String] :base-url the base URL (hyphenated key)
  # @option opts [String] :"content-type" content type header (symbol with hyphens)
  # @return [Hash] processed options
  def special_char_options(opts)
    opts
  end

  # Method with duplicate @option definitions (same key twice)
  # @param config [Hash] configuration hash
  # @option config [String] :name the name as string
  # @option config [Integer] :name the name as integer (duplicate!)
  # @return [Hash] result
  def duplicate_options(config)
    config
  end

  # Method with multiple Hash parameters and options
  # @param user_config [Hash] user configuration
  # @param system_config [Hash] system configuration
  # @option user_config [String] :username the username
  # @option user_config [String] :email the email
  # @option system_config [Integer] :max_connections maximum connections
  # @option system_config [Boolean] :debug_mode debug mode enabled
  # @return [Hash] merged configuration
  def multiple_hash_params(user_config, system_config)
    user_config.merge(system_config)
  end

  # Method with keyword arguments (not Hash param) but using @option
  # @param name [String] the name
  # @param age [Integer] the age
  # @option name [String] :wrong this is incorrect - keyword args aren't Hash params
  # @return [Hash] user data
  def keyword_args_with_option(name:, age:)
    { name: name, age: age }
  end

  # Method with options but wrong tag order
  # @option config [String] :key the key value
  # @param config [Hash] configuration hash (should come before @option)
  # @return [Hash] result
  def wrong_order_options(config)
    config
  end
end

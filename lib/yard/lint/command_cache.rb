# frozen_string_literal: true

module Yard
  module Lint
    # Cache for YARD command executions to avoid running identical commands multiple times
    # This provides a transparent optimization layer - validators don't need to know about it
    class CommandCache
      def initialize
        @cache = {}
        @hits = 0
        @misses = 0
      end

      # Execute a command through the cache
      # If the command has been executed before, return cached result
      # Otherwise execute and cache the result
      # @param command_string [String] the shell command to execute
      # @return [Hash] hash with stdout, stderr, exit_code keys
      # @note Returns a deep clone to prevent validators from modifying cached data
      def execute(command_string)
        cache_key = generate_cache_key(command_string)

        if @cache.key?(cache_key)
          @hits += 1
          deep_clone(@cache[cache_key])
        else
          @misses += 1
          result = execute_command(command_string)
          @cache[cache_key] = deep_clone(result)
          result
        end
      end

      # Get cache statistics
      # @return [Hash] hash with hits, misses, and total executions
      def stats
        {
          hits: @hits,
          misses: @misses,
          total: @hits + @misses,
          saved_executions: @hits
        }
      end

      private

      # Generate a cache key for the command
      # Normalizes the command to handle whitespace differences
      # @param command_string [String] the command to generate key for
      # @return [String] SHA256 hash of normalized command
      def generate_cache_key(command_string)
        # Normalize whitespace: collapse multiple spaces/newlines into single spaces
        normalized = command_string.strip.gsub(/\s+/, ' ')
        Digest::SHA256.hexdigest(normalized)
      end

      # Actually execute the command
      # @param command_string [String] the command to execute
      # @return [Hash] hash with stdout, stderr, exit_code keys
      def execute_command(command_string)
        # Set up environment to load IRB shim before YARD (Ruby 3.5+ compatibility)
        env = build_environment_with_shim

        stdout, stderr, status = Open3.capture3(env, command_string)
        {
          stdout: stdout,
          stderr: stderr,
          exit_code: status.exitstatus
        }
      end

      # Build environment hash with RUBYOPT to load IRB shim
      # This ensures the shim is loaded in subprocesses (like yard list commands)
      # @return [Hash] environment variables for command execution
      def build_environment_with_shim
        shim_path = File.expand_path('ext/irb_notifier_shim.rb', __dir__)
        rubyopt = "-r#{shim_path}"

        # Preserve existing RUBYOPT if present
        rubyopt = "#{ENV['RUBYOPT']} #{rubyopt}" if ENV['RUBYOPT']

        { 'RUBYOPT' => rubyopt }
      end

      # Deep clone a hash to prevent modifications to cached data
      # @param hash [Hash] the hash to clone
      # @return [Hash] deep cloned hash
      def deep_clone(hash)
        Marshal.load(Marshal.dump(hash))
      end
    end
  end
end

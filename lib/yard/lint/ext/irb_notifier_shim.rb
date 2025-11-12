# frozen_string_literal: true

# Shim for IRB::Notifier to avoid IRB dependency in Ruby 3.5+
#
# YARD's legacy parser vendors old IRB code that depends on IRB::Notifier.
# In Ruby 3.5+, IRB is no longer part of the default gems and must be explicitly installed.
# This shim provides just enough functionality to keep YARD's legacy parser working
# without requiring the full IRB gem as a dependency.
#
# The notifier is only used for debug output in YARD's legacy parser, which we don't need.
#
# IMPORTANT: This shim only loads if IRB::Notifier is not already defined.
# If IRB gem is present, we use the real implementation instead.

# Only load the shim if IRB::Notifier is not already defined
unless defined?(IRB::Notifier)
  # Try to load the real IRB notifier first
  # If it fails (IRB not installed), we'll provide our shim
  begin
    require 'irb/notifier'
  rescue LoadError
    # IRB not available, use our shim
    # Mark as loaded to prevent further require attempts
    $LOADED_FEATURES << 'irb/notifier.rb'

    module IRB
      # Minimal Notifier implementation that does nothing
      # YARD's legacy parser uses this for debug output which we can safely ignore
      class Notifier
        # No-op message level constant
        D_NOMSG = 0

        class << self
          # Returns a no-op notifier
          # @param _prefix [String] notification prefix (ignored)
          # @return [NoOpNotifier] a notifier that does nothing
          def def_notifier(_prefix)
            NoOpNotifier.new
          end
        end

        # A notifier that silently discards all output
        class NoOpNotifier
          attr_accessor :level

          def initialize
            @level = Notifier::D_NOMSG
          end

          # Returns a no-op notifier for any sub-level
          # @param _level [Integer] notification level (ignored)
          # @param _prefix [String] notification prefix (ignored)
          # @return [NoOpNotifier] a notifier that does nothing
          def def_notifier(_level, _prefix)
            NoOpNotifier.new
          end

          # Silently ignore pretty-print calls
          # @param _obj [Object] object to pretty-print (ignored)
          # @return [nil]
          def pp(_obj)
            nil
          end

          # Silently ignore print calls
          # @param _args [Array] print arguments (ignored)
          # @return [nil]
          def print(*_args)
            nil
          end

          # Silently ignore puts calls
          # @param _args [Array] puts arguments (ignored)
          # @return [nil]
          def puts(*_args)
            nil
          end

          # Silently ignore printf calls
          # @param _args [Array] printf arguments (ignored)
          # @return [nil]
          def printf(*_args)
            nil
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

# Shim for IRB::Notifier to avoid IRB dependency in Ruby 3.5+/4.0+
#
# WHY THIS SHIM IS NEEDED:
# In Ruby 3.5+, IRB is no longer part of the default gems and must be explicitly installed.
# YARD's codebase has a dependency chain that triggers `require "irb/notifier"` even when
# using the modern Ripper-based parser:
#
#   @!attribute directive parsing
#     → YARD::Tags::OverloadTag#parse_signature
#       → YARD::Parser::Ruby::Legacy::TokenList
#         → ruby_lex.rb
#           → irb/slex.rb
#             → require "irb/notifier"  ← FAILS without IRB gem or this shim
#
# This happens because YARD uses its legacy TokenList for parsing attribute signatures,
# regardless of which main parser is selected. Until YARD removes this dependency,
# this shim is required for Ruby 3.5+/4.0+ compatibility.
#
# WHAT THIS SHIM DOES:
# Provides a minimal no-op implementation of IRB::Notifier that satisfies YARD's
# requirements. The notifier is only used for debug output which we don't need.
#
# IMPORTANT: This shim only loads if IRB::Notifier is not already defined.
# If the IRB gem is present, we use the real implementation instead.

# Only load the shim if IRB::Notifier is not already defined
unless defined?(IRB::Notifier)
  # Try to load the real IRB notifier first
  # If it fails (IRB not installed), we'll provide our shim
  begin
    # Suppress warnings during require attempt (Ruby 3.5+ warns about missing default gems)
    original_verbose = $VERBOSE
    $VERBOSE = nil
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
  ensure
    # Restore original verbosity setting
    $VERBOSE = original_verbose
  end
end

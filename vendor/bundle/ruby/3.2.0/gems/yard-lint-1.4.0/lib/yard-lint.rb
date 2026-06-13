# frozen_string_literal: true

# Load IRB notifier shim before YARD to avoid IRB dependency in Ruby 3.5+/4.0+
# This must be loaded before any YARD code is required
require_relative 'yard/lint/ext/irb_notifier_shim'

require 'zeitwerk'

# Setup Zeitwerk loader for gem
loader = Zeitwerk::Loader.for_gem(warn_on_extra_files: false)
loader.ignore(__FILE__)
loader.ignore("#{__dir__}/yard/lint/ext")
loader.ignore("#{__dir__}/yard/lint/version.rb")
loader.setup

# Manually load files that don't follow Zeitwerk naming conventions
require_relative 'yard/lint/version'
require_relative 'yard/lint'

# frozen_string_literal: true

require 'zeitwerk'

# Setup Zeitwerk loader for gem
loader = Zeitwerk::Loader.for_gem(warn_on_extra_files: false)
loader.ignore(__FILE__)
loader.setup

# Manually load the main module since it contains class-level methods
require_relative 'yard/lint'

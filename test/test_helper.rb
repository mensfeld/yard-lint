# frozen_string_literal: true

require 'fileutils'
require 'tempfile'
require 'stringio'

# Only track coverage on Ruby 4.0
if RUBY_VERSION.start_with?('4.0')
  require 'simplecov'

  SimpleCov.start do
    add_filter '/test/'
    add_filter '/vendor/'

    minimum_coverage 95
  end
end

require 'minitest/autorun'
require 'mocha/minitest'

require 'yard-lint'

# Helper method for creating test configs without default exclusions
# This is needed for integration tests that use fixture files in test/fixtures/
# @param block [Proc] optional block for additional configuration
# @return [Yard::Lint::Config] config object with no exclusions
def test_config(&block)
  Yard::Lint::Config.new do |c|
    c.exclude = [] # Clear default exclusions that would filter out test/fixtures
    block&.call(c)
  end
end

# Clear YARD registry to ensure clean start
YARD::Registry.clear

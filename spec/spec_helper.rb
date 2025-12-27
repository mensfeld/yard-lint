# frozen_string_literal: true

require 'fileutils'
require 'tempfile'
require 'stringio'

# Only track coverage on Ruby 4.0
if RUBY_VERSION.start_with?('4.0')
  require 'simplecov'

  SimpleCov.start do
    add_filter '/spec/'
    add_filter '/vendor/'

    minimum_coverage 95
  end
end

require 'yard-lint'

# Helper method for creating test configs without default exclusions
# This is needed for integration tests that use fixture files in spec/fixtures/
# @param block [Proc] optional block for additional configuration
# @return [Yard::Lint::Config] config object with no exclusions
def test_config(&block)
  Yard::Lint::Config.new do |c|
    c.exclude = [] # Clear default exclusions that would filter out spec/fixtures
    block&.call(c)
  end
end

RSpec.configure do |config|
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Clear YARD registry before the entire suite to ensure clean start
  config.before(:suite) do
    YARD::Registry.clear
  end
end

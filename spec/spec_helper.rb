# frozen_string_literal: true

require 'simplecov'
require 'fileutils'

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/vendor/'

  minimum_coverage 95
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

  # Only reset cache for tests that explicitly need isolation
  # Use :cache_isolation tag to force cache clearing for specific tests
  config.before(:each, :cache_isolation) do
    Yard::Lint::Validators::Base.reset_command_cache!
    Yard::Lint::Validators::Base.clear_yard_database!
  end

  # Clear cache once before the entire suite to ensure clean start
  config.before(:suite) do
    Yard::Lint::Validators::Base.reset_command_cache!
    Yard::Lint::Validators::Base.clear_yard_database!
  end

  # Clear cache after the entire suite to clean up
  config.after(:suite) do
    Yard::Lint::Validators::Base.clear_yard_database!
  end
end

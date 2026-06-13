# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

# BUG-046: Tags/ExampleSyntax compiles every @example body as Ruby, so an irb /
# pry / shell transcript (or its `=>` output lines) is reported as a syntax
# error. The opt-in SkipNonRuby option (default false) skips @example blocks
# that are interactive console transcripts rather than runnable Ruby.
describe 'Tags/ExampleSyntax SkipNonRuby' do
  attr_reader :test_dir

  before do
    @test_dir = Dir.mktmpdir
  end

  after do
    FileUtils.rm_rf(@test_dir) if @test_dir && File.exist?(@test_dir)
  end

  def write_file(content)
    path = File.join(@test_dir, 'test.rb')
    File.write(path, content)
    path
  end

  def offenses_for(content, skip_non_ruby:)
    config = test_config do |c|
      c.set_validator_config('Tags/ExampleSyntax', 'Enabled', true)
      c.set_validator_config('Tags/ExampleSyntax', 'SkipNonRuby', skip_non_ruby)
    end
    path = write_file(content)
    result = Yard::Lint.run(path: path, config: config, progress: false)
    result.offenses.select { |o| o[:name] == 'ExampleSyntax' }
  end

  IRB = <<~RUBY
    # Looks up a user.
    # @example
    #   >> user.name
    #   => "Bob"
    def lookup; end
  RUBY

  IRB_PROMPT = <<~RUBY
    # Adds.
    # @example
    #   irb(main):001:0> 1 + 1
    #   => 2
    def add; end
  RUBY

  PRY = <<~RUBY
    # Adds.
    # @example
    #   [1] pry(main)> 2 + 2
    #   => 4
    def add; end
  RUBY

  SHELL = <<~RUBY
    # Installs.
    # @example
    #   $ bundle install
    #   Fetching gem metadata...
    def install; end
  RUBY

  it 'is off by default: an irb transcript is still flagged' do
    refute_empty(offenses_for(IRB, skip_non_ruby: false))
  end

  it 'when enabled: skips an irb transcript (>> / =>)' do
    assert_empty(offenses_for(IRB, skip_non_ruby: true))
  end

  it 'when enabled: skips an irb prompt transcript' do
    assert_empty(offenses_for(IRB_PROMPT, skip_non_ruby: true))
  end

  it 'when enabled: skips a pry transcript' do
    assert_empty(offenses_for(PRY, skip_non_ruby: true))
  end

  it 'when enabled: skips a shell session' do
    assert_empty(offenses_for(SHELL, skip_non_ruby: true))
  end

  it 'when enabled: still flags a genuine Ruby syntax error' do
    content = <<~RUBY
      # Broken example.
      # @example
      #   def broken(
      #     missing paren
      #   end
      def thing; end
    RUBY
    refute_empty(offenses_for(content, skip_non_ruby: true))
  end

  it 'when enabled: does not skip valid Ruby that happens to use a hash rocket' do
    content = <<~RUBY
      # Builds a map.
      # @example
      #   mapping = { :a => 1, :b => 2 }
      #   mapping.fetch(:a)
      def build; end
    RUBY
    assert_empty(offenses_for(content, skip_non_ruby: true))
  end
end

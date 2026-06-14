# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

# BUG-051: Tags/InformalNotation skips fenced (```) code blocks but not
# 4-space-indented Markdown code blocks, so informal-looking text inside an
# indented code sample (e.g. "Note:") was flagged. The opt-in
# SkipIndentedCodeBlocks option (default false) makes it also skip lines that
# are part of an indented code block.
describe 'Tags/InformalNotation SkipIndentedCodeBlocks' do
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

  def offenses_for(content, skip_indented:)
    config = test_config do |c|
      c.set_validator_config('Tags/InformalNotation', 'Enabled', true)
      c.set_validator_config('Tags/InformalNotation', 'SkipIndentedCodeBlocks', skip_indented)
    end
    path = write_file(content)
    result = Yard::Lint.run(path: path, config: config, progress: false)
    result.offenses.select { |o| o[:name] == 'InformalNotation' }
  end

  INDENTED = <<~RUBY
    # Builds a thing.
    #
    # Example usage:
    #
    #     Note: indented code, not a real informal note
    #     Todo: also code
    #
    # @return [void]
    def build; end
  RUBY

  it 'is off by default: informal text in an indented code block is still flagged' do
    offenses = offenses_for(INDENTED, skip_indented: false)
    refute_empty(offenses)
  end

  it 'when enabled: does not flag informal text inside an indented code block' do
    offenses = offenses_for(INDENTED, skip_indented: true)
    assert_empty(offenses)
  end

  it 'when enabled: still flags informal notation in ordinary (non-indented) prose' do
    content = <<~RUBY
      # Builds a thing.
      #
      # Note: this is real prose and should be flagged.
      #
      # @return [void]
      def build; end
    RUBY
    offenses = offenses_for(content, skip_indented: true)
    refute_empty(offenses)
    assert_includes(offenses.first[:message], '@note')
  end

  it 'when enabled: still skips fenced code blocks (unchanged behaviour)' do
    content = <<~RUBY
      # Builds a thing.
      #
      # ```
      # Note: fenced code
      # ```
      #
      # @return [void]
      def build; end
    RUBY
    offenses = offenses_for(content, skip_indented: true)
    assert_empty(offenses)
  end
end

# frozen_string_literal: true

require 'test_helper'

require 'tmpdir'
require 'fileutils'

describe 'Markdown Syntax' do
  attr_reader :config


  before do
    @config = Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/MarkdownSyntax', 'Enabled', true)
    end
    @test_dir = Dir.mktmpdir
  end

  after do
    FileUtils.rm_rf(@test_dir) if @test_dir && File.exist?(@test_dir)
  end

  def create_test_file(filename, content)
    path = File.join(@test_dir, filename)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
    path
  end

  it 'when documentation has unclosed backtick detects the error' do
    file = create_test_file('unclosed_backtick.rb', <<~RUBY)
      # Process data with `unclosed backtick
      def process(data)
        # implementation
      end
    RUBY

    result = Yard::Lint.run(path: file, config: config)
    markdown_errors = result.offenses.select { |o| o[:name].to_s == 'MarkdownSyntax' }

    refute_empty(markdown_errors)
    assert_includes(markdown_errors.first[:message], 'Unclosed backtick')
  end

  it 'when documentation has unclosed bold detects the error' do
    file = create_test_file('unclosed_bold.rb', <<~RUBY)
      # Process data with **bold text that is not closed
      def process(data)
        # implementation
      end
    RUBY

    result = Yard::Lint.run(path: file, config: config)
    markdown_errors = result.offenses.select { |o| o[:name].to_s == 'MarkdownSyntax' }

    refute_empty(markdown_errors)
    assert_includes(markdown_errors.first[:message], 'Unclosed bold formatting')
  end

  it 'when documentation has invalid list marker detects the error' do
    file = create_test_file('invalid_list.rb', <<~RUBY)
      # Process data
      # \u2022 Invalid bullet point
      def process(data)
        # implementation
      end
    RUBY

    result = Yard::Lint.run(path: file, config: config)
    markdown_errors = result.offenses.select { |o| o[:name].to_s == 'MarkdownSyntax' }

    refute_empty(markdown_errors)
    assert_includes(markdown_errors.first[:message], 'Invalid list marker')
  end

  it 'when documentation has valid markdown does not flag the method' do
    file = create_test_file('valid_markdown.rb', <<~RUBY)
      # Process data with `proper code` and **bold** text
      # - Valid list item
      # * Another valid item
      def process(data)
        # implementation
      end
    RUBY

    result = Yard::Lint.run(path: file, config: config)
    markdown_errors = result.offenses.select { |o| o[:name].to_s == 'MarkdownSyntax' }

    assert_empty(markdown_errors)
  end

  it 'when documentation has multiple errors detects all errors' do
    file = create_test_file('multiple_errors.rb', <<~RUBY)
      # Process data with `unclosed backtick and **unclosed bold
      def process(data)
        # implementation
      end
    RUBY

    result = Yard::Lint.run(path: file, config: config)
    markdown_errors = result.offenses.select { |o| o[:name].to_s == 'MarkdownSyntax' }

    refute_empty(markdown_errors)
    message = markdown_errors.first[:message]
    assert_includes(message, 'Unclosed backtick')
    assert_includes(message, 'Unclosed bold formatting')
  end
end

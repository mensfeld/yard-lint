# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

describe 'TextSubstitution' do
  attr_reader :fixture_path, :config, :test_dir

  before do
    @fixture_path = File.expand_path('../fixtures/text_substitution_examples.rb', __dir__)
    @config = test_config do |c|
      c.set_validator_config('Documentation/TextSubstitution', 'Enabled', true)
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

  def text_sub_offenses(result)
    result.offenses.select { |o| o[:name].to_s == 'TextSubstitution' }
  end

  it 'detects em-dash in documentation' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
    offenses = text_sub_offenses(result).select { |o| o[:forbidden] == "—" }
    refute_empty(offenses)
    assert(offenses.all? { |o| o[:message].include?("'—'") })
    assert(offenses.all? { |o| o[:message].include?("'-'") })
  end

  it 'detects en-dash in documentation' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
    offenses = text_sub_offenses(result).select { |o| o[:forbidden] == "–" }
    refute_empty(offenses)
  end

  it 'does not flag plain hyphens' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
    offenses = text_sub_offenses(result)
    plain_offenses = offenses.select { |o| o[:object_name]&.include?('plain_hyphen') }
    assert_empty(plain_offenses)
  end

  it 'does not flag content inside fenced code blocks' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
    offenses = text_sub_offenses(result)
    code_block_offenses = offenses.select { |o| o[:object_name]&.include?('with_code_block') }
    assert_empty(code_block_offenses)
  end

  it 'is disabled by default' do
    default_config = test_config
    result = Yard::Lint.run(path: fixture_path, config: default_config, progress: false)
    assert_empty(text_sub_offenses(result))
  end

  it 'reports two separate violations when both em-dash and en-dash appear on the same line' do
    file = create_test_file('multi_violation.rb', <<~RUBY)
      # Both em-dash — and en-dash – on one line.
      def multi_violation_method
        :ok
      end
    RUBY

    result = Yard::Lint.run(path: file, config: config, progress: false)
    offenses = text_sub_offenses(result)

    assert_equal(2, offenses.size)
    assert_includes(offenses.map { |o| o[:forbidden] }, "—")
    assert_includes(offenses.map { |o| o[:forbidden] }, "–")
  end

  it 'respects user-configured substitutions' do
    custom_config = test_config do |c|
      c.set_validator_config('Documentation/TextSubstitution', 'Enabled', true)
      c.set_validator_config('Documentation/TextSubstitution', 'Substitutions',
                             { '...' => 'ellipsis' })
    end

    file = create_test_file('custom_sub.rb', <<~RUBY)
      # Loading... please wait.
      def loading_method
        :loading
      end
    RUBY

    result = Yard::Lint.run(path: file, config: custom_config, progress: false)
    offenses = text_sub_offenses(result)
    refute_empty(offenses)
    assert_includes(offenses.first[:message], "Replace '...' with 'ellipsis'")
  end

  it 'includes the offending line text in the message' do
    file = create_test_file('msg_format.rb', <<~RUBY)
      # Connects the start — and end.
      def msg_format_method
        :ok
      end
    RUBY

    result = Yard::Lint.run(path: file, config: config, progress: false)
    offenses = text_sub_offenses(result)
    refute_empty(offenses)
    assert_includes(offenses.first[:message], 'Found:')
  end

  it 'offense name is TextSubstitution' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
    offenses = text_sub_offenses(result)
    refute_empty(offenses)
    assert(offenses.all? { |o| o[:name].to_s == 'TextSubstitution' })
  end

  it 'offense severity is warning by default' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
    offenses = text_sub_offenses(result)
    refute_empty(offenses)
    assert(offenses.all? { |o| o[:severity] == 'warning' })
  end

  it 'offense validator is Documentation/TextSubstitution' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
    offenses = text_sub_offenses(result)
    refute_empty(offenses)
    assert(offenses.all? { |o| o[:validator] == 'Documentation/TextSubstitution' })
  end
end

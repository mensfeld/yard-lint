# frozen_string_literal: true

describe 'Yard::Lint::Validators::Documentation::UnderfilledLines' do
  it 'is a module' do
    assert_kind_of(Module, Yard::Lint::Validators::Documentation::UnderfilledLines)
  end

  it 'has required sub modules and classes' do
    mod = Yard::Lint::Validators::Documentation::UnderfilledLines
    assert_equal(true, mod.const_defined?(:Config))
    assert_equal(true, mod.const_defined?(:Validator))
    assert_equal(true, mod.const_defined?(:Parser))
    assert_equal(true, mod.const_defined?(:Result))
    assert_equal(true, mod.const_defined?(:MessagesBuilder))
  end

  it 'is discovered by the config loader' do
    assert_includes(Yard::Lint::ConfigLoader::ALL_VALIDATORS, 'Documentation/UnderfilledLines')
  end
end

describe 'Documentation/UnderfilledLines integration' do
  # Run the validator against an in-memory source file and return only its offenses.
  # @param source [String] Ruby source to lint
  # @param opts [Hash] per-test overrides for the validator config
  # @return [Array<Hash>] offenses produced by Documentation/UnderfilledLines
  def underfilled_offenses(source, **opts)
    Tempfile.create(['underfilled', '.rb']) do |file|
      file.write(source)
      file.flush

      config = test_config do |c|
        c.set_validator_config('Documentation/UnderfilledLines', 'Enabled', true)
        opts.each { |key, value| c.set_validator_config('Documentation/UnderfilledLines', key.to_s, value) }
      end

      result = Yard::Lint.run(path: file.path, config: config)
      return result.offenses.select { |offense| offense[:validator] == 'Documentation/UnderfilledLines' }
    end
  end

  # --- Positives: should be flagged ---

  it 'flags prose that wraps at roughly half the available width' do
    offenses = underfilled_offenses(<<~RUBY)
      # Processes the incoming payload and returns a normalized
      # hash that downstream consumers can rely on for routing.
      def process(payload); end
    RUBY

    assert_equal(1, offenses.size)
    assert_match(/uses 2 lines but fits in 1/, offenses.first[:message])
  end

  it 'flags a three-line paragraph that reflows to fewer lines' do
    offenses = underfilled_offenses(<<~RUBY)
      # This method validates the configuration object before it is
      # handed off to the executor so that invalid settings are caught
      # early instead of failing deep inside the run later on today.
      def validate; end
    RUBY

    assert_equal(1, offenses.size)
  end

  it 'flags underfilled prose on a class docstring' do
    offenses = underfilled_offenses(<<~RUBY)
      # A small value object that wraps a user identifier and
      # exposes helpers for formatting it in logs and metrics.
      class UserId; end
    RUBY

    assert_equal(1, offenses.size)
  end

  it 'flags underfilled prose on a module docstring' do
    offenses = underfilled_offenses(<<~RUBY)
      # Provides retry semantics for transient network failures
      # using an exponential backoff strategy with jitter applied.
      module Retryable; end
    RUBY

    assert_equal(1, offenses.size)
  end

  it 'flags a line that wraps after a comma (comma is not a default boundary)' do
    offenses = underfilled_offenses(<<~RUBY)
      # It accepts an options hash, a logger, and a clock,
      # then wires them together into a ready-to-use service.
      def build; end
    RUBY

    assert_equal(1, offenses.size)
  end

  it 'reports one offense per wasteful paragraph' do
    offenses = underfilled_offenses(<<~RUBY)
      # This first paragraph wraps much too early and it
      # clearly wastes a good amount of the available room.
      #
      # This second paragraph also wraps far too early and
      # similarly fails to use the width that is available.
      def thing; end
    RUBY

    assert_equal(2, offenses.size)
  end

  it 'points the offense at the first line of the paragraph' do
    offenses = underfilled_offenses(<<~RUBY)
      # Processes the incoming payload and returns a normalized
      # hash that downstream consumers can rely on for routing.
      def process(payload); end
    RUBY

    assert_equal(1, offenses.first[:line])
  end

  it 'produces a convention-severity offense' do
    offenses = underfilled_offenses(<<~RUBY)
      # Processes the incoming payload and returns a normalized
      # hash that downstream consumers can rely on for routing.
      def process(payload); end
    RUBY

    assert_equal('convention', offenses.first[:severity])
  end

  # --- Negatives: must not be flagged ---

  it 'does not flag a single-line docstring' do
    assert_empty underfilled_offenses(<<~RUBY)
      # Returns the user id.
      def id; end
    RUBY
  end

  it 'does not flag semantic line breaks (one sentence per line)' do
    assert_empty underfilled_offenses(<<~RUBY)
      # Validates the input.
      # Normalizes the casing.
      # Persists the record.
      def call; end
    RUBY
  end

  it 'does not flag a near-full first line (below the trailing-space threshold)' do
    assert_empty underfilled_offenses(<<~RUBY)
      # This first sentence has been deliberately written so that it very nearly reaches the maximum width,
      # done.
      def x; end
    RUBY
  end

  it 'does not flag a colon-introduced markdown list' do
    assert_empty underfilled_offenses(<<~RUBY)
      # Supported formats:
      # - json
      # - yaml
      def formats; end
    RUBY
  end

  it 'does not flag a markdown table' do
    assert_empty underfilled_offenses(<<~RUBY)
      # | name | type    |
      # |------|---------|
      # | id   | Integer |
      def table; end
    RUBY
  end

  it 'does not flag a fenced code block' do
    assert_empty underfilled_offenses(<<~RUBY)
      # Example:
      # ```ruby
      # do_it
      # done
      # ```
      def example; end
    RUBY
  end

  it 'does not flag short lines inside an @example block' do
    assert_empty underfilled_offenses(<<~RUBY)
      # Greets the user nicely.
      # @example
      #   greet("a")
      #   greet("b")
      def greet(name); end
    RUBY
  end

  it 'does not flag short tag descriptions or their wrapped continuations' do
    assert_empty underfilled_offenses(<<~RUBY)
      # Does a thing here.
      # @param value [String] the value
      # @return [String] the
      #   normalized value
      def doit(value); end
    RUBY
  end

  it 'does not flag a directive block' do
    assert_empty underfilled_offenses(<<~RUBY)
      # @!macro [new] retry
      #   Retries on failure.
      def m; end
    RUBY
  end

  it 'does not flag when the next line starts with an unbreakable long URL' do
    assert_empty underfilled_offenses(<<~RUBY)
      # See the migration guide for details before you upgrade
      # https://example.com/some/really/long/path/that/cannot/be/wrapped/at/all/here/ok
      def migrate; end
    RUBY
  end

  it 'does not flag when the next line is an unbreakable namespaced constant' do
    assert_empty underfilled_offenses(<<~RUBY)
      # Delegates resolution to the configured singleton
      # Application::Services::Authentication::TokenVerifier::Strategy::Implementation instance.
      def resolve; end
    RUBY
  end

  it 'does not flag an indented ascii diagram under a header' do
    assert_empty underfilled_offenses(<<~RUBY)
      # Pipeline:
      #   input -> parse -> transform -> output here
      #   each stage is pure and total here as well
      def pipe; end
    RUBY
  end

  it 'does not flag non-ascii prose by default' do
    assert_empty underfilled_offenses(<<~RUBY)
      # このメソッドはユーザー識別子を正規化して返します。
      # ログとメトリクスでの表示に使用されます。
      def jp; end
    RUBY
  end

  it 'does not flag a line ending in an abbreviation' do
    assert_empty underfilled_offenses(<<~RUBY)
      # Accepts several serialization formats, e.g.
      # JSON and YAML, and picks one based on the header.
      def fmt; end
    RUBY
  end

  it 'does not flag blockquotes and thematic breaks' do
    assert_empty underfilled_offenses(<<~RUBY)
      # > Note: this will be deprecated soon enough.
      # ---
      # Use the new API instead of the old one here.
      def old; end
    RUBY
  end

  it 'does not flag column-aligned key/value prose' do
    assert_empty underfilled_offenses(<<~RUBY)
      # Options here:
      #   timeout   the read timeout in seconds used
      #   retries   number of attempts before giving up
      def cfg; end
    RUBY
  end

  it 'does not flag a paragraph that is already nearly full' do
    assert_empty underfilled_offenses(<<~RUBY)
      # This paragraph is wrapped quite tightly and each line already reaches close to the limit here,
      # so reflowing it would not actually save any vertical space at all in practice today as such.
      def tight; end
    RUBY
  end

  # --- Configuration ---

  it 'does not run unless explicitly enabled' do
    Tempfile.create(['underfilled', '.rb']) do |file|
      file.write("# wraps far too early and could be\n# joined together onto a single line here.\ndef x; end\n")
      file.flush

      result = Yard::Lint.run(path: file.path, config: test_config)
      assert_empty(result.offenses.select { |o| o[:validator] == 'Documentation/UnderfilledLines' })
    end
  end

  it 'honors a custom MaxLength' do
    source = <<~RUBY
      # This paragraph fits comfortably within roughly seventy
      # columns and so it only looks underfilled at wide limits.
      def narrow; end
    RUBY

    assert_equal(1, underfilled_offenses(source, MaxLength: 120).size)
    assert_empty underfilled_offenses(source, MaxLength: 80)
  end

  it 'respects comma breaks when comma is added to SentenceEndChars' do
    source = <<~RUBY
      # It accepts an options hash, a logger, and a clock,
      # then wires them together into a ready-to-use service.
      def build; end
    RUBY

    assert_equal(1, underfilled_offenses(source).size)
    assert_empty underfilled_offenses(source, SentenceEndChars: ['.', '?', '!', ':', ';', ','])
  end

  it 'honors a custom MinTrailingSpace' do
    source = <<~RUBY
      # Processes the incoming payload and returns a normalized
      # hash that downstream consumers can rely on for routing.
      def process(payload); end
    RUBY

    assert_equal(1, underfilled_offenses(source, MinTrailingSpace: 20).size)
    assert_empty underfilled_offenses(source, MinTrailingSpace: 90)
  end
end

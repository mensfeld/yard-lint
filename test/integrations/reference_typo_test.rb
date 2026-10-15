# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

describe 'Documentation/ReferenceTypo' do
  attr_reader :dir

  before { @dir = Dir.mktmpdir }
  after { FileUtils.rm_rf(dir) }

  # Lint the given source and return only this validator's offenses.
  # @param source [String] Ruby source to lint
  # @return [Array<Hash>] offenses produced by Documentation/ReferenceTypo
  def offenses_for(source)
    path = File.join(dir, 'example.rb')
    File.write(path, source)

    Yard::Lint
      .run(path: path, config: test_config, progress: false)
      .offenses
      .select { |offense| offense[:validator] == 'Documentation/ReferenceTypo' }
  end

  # @param source [String] Ruby source to lint
  # @return [Array<String>] offense messages
  def messages_for(source)
    offenses_for(source).map { |offense| offense[:message] }
  end

  it 'flags a misspelled method in a link and suggests the closest name' do
    messages = messages_for(<<~RUBY)
      # Parser
      class ReferenceParser
        # Parses
        def parse; end

        # Delegates to {ReferenceParser#prase}
        def call; end
      end
    RUBY

    assert_equal(
      ["Reference 'ReferenceParser#prase' does not resolve (did you mean 'ReferenceParser#parse'?)"],
      messages
    )
  end

  it 'flags namespace-relative links, @see targets and class methods' do
    messages = messages_for(<<~RUBY)
      # Parser
      class ReferenceParser
        # Parses
        def parse; end

        # Builds
        def self.build; end

        # Delegates to {#prase} and {ReferenceParser.biuld}
        # @see ReferenceParser#parsee
        def call; end
      end
    RUBY

    assert_includes(messages, "Reference '#prase' does not resolve (did you mean '#parse'?)")
    assert_includes(
      messages,
      "Reference 'ReferenceParser.biuld' does not resolve (did you mean 'ReferenceParser.build'?)"
    )
    assert_includes(
      messages,
      "Reference 'ReferenceParser#parsee' does not resolve (did you mean 'ReferenceParser#parse'?)"
    )
  end

  it 'flags misspelled constants and namespaces' do
    messages = messages_for(<<~RUBY)
      # App
      module ReferenceApp
        # Default timeout
        TIMEOUT = 5

        # Worker
        class Worker
          # Runs
          def run; end

          # Uses {ReferenceApp::TIMEUOT}, {Wroker} and {ReferenceApp::Wroker#run}
          def call; end
        end
      end
    RUBY

    assert_includes(
      messages,
      "Reference 'ReferenceApp::TIMEUOT' does not resolve (did you mean 'ReferenceApp::TIMEOUT'?)"
    )
    assert_includes(messages, "Reference 'Wroker' does not resolve (did you mean 'Worker'?)")
    assert_includes(
      messages,
      "Reference 'ReferenceApp::Wroker#run' does not resolve (did you mean 'ReferenceApp::Worker#run'?)"
    )
  end

  it 'checks links in tag text and inside overloads' do
    messages = messages_for(<<~RUBY)
      # Parser
      class ReferenceParser
        # Parses
        def parse; end

        # Calls
        # @param input [String] passed to {#prase}
        # @overload call(input, strict)
        #   Strict variant of {#parze}
        #   @param strict [Boolean] strict
        def call(input, strict = false); end
      end
    RUBY

    assert_includes(messages, "Reference '#prase' does not resolve (did you mean '#parse'?)")
    assert_includes(messages, "Reference '#parze' does not resolve (did you mean '#parse'?)")
  end

  it 'does not flag references that resolve, including inherited methods' do
    offenses = offenses_for(<<~RUBY)
      # Base
      class ReferenceBase
        # Parses
        def parse; end
      end

      # Child
      class ReferenceChild < ReferenceBase
        # Delegates to {#parse}, {ReferenceBase#parse} and {ReferenceChild#parse}
        # @see ReferenceBase
        def call; end
      end
    RUBY

    assert_empty(offenses)
  end

  it 'does not flag methods that resolve two or more namespaces up' do
    offenses = offenses_for(<<~RUBY)
      # App
      module ReferenceApp
        # Client
        class Client
          # Runs
          def run; end

          # Runs many
          def runs; end
        end

        # Sub
        module Sub
          # Uses {Client#run} and {ReferenceApp::Client#run}
          # @see ReferenceApp::Client#run
          class Worker
            # Calls {Client#run}
            # @see Client#run
            def go; end
          end
        end
      end
    RUBY

    assert_empty(offenses)
  end

  it 'does not flag references into unknown or external namespaces' do
    offenses = offenses_for(<<~RUBY)
      # Parser
      class ReferenceParser
        # Parses
        def parse; end

        # See {String#upcse}, {Foo::Bar#baz}, {Strng}, {Hash#fecth} and
        # {https://example.com}
        # @see https://example.com
        # @see Net::HTTP#get
        def call; end
      end
    RUBY

    assert_empty(offenses)
  end

  it 'does not suggest a root-level name for a bare constant of an unloaded gem' do
    offenses = offenses_for(<<~RUBY)
      # Root namespace
      module Karafka
        # Producer
        class Producer
          # See {Kafka} and {Kafka::Client#call}
          # @see Kafka
          def call; end
        end
      end
    RUBY

    assert_empty(offenses)
  end

  it 'does not flag methods a loaded Ruby ancestor defines' do
    offenses = offenses_for(<<~RUBY)
      # Parser
      class ReferenceParser
        # Hash form
        def to_h; end

        # Error form
        def to_e; end

        # See {#to_s} and {#inspect}
        def call; end
      end

      # Error with a typo'd link into an external superclass
      class ReferenceError < StandardError
        # Formats
        def format_message; end

        # See {#full_message} and {#backtrace}
        def call; end
      end
    RUBY

    assert_empty(offenses)
  end

  it 'does not flag a namespace whose ancestor is not loaded' do
    offenses = offenses_for(<<~RUBY)
      # Model
      class ReferenceModel < SomeGem::Base
        # Saves
        def save; end

        # See {#safe}
        def call; end
      end
    RUBY

    assert_empty(offenses)
  end

  it 'ignores links inside code spans and hash literals' do
    offenses = offenses_for(<<~RUBY)
      # Parser
      class ReferenceParser
        # Parses
        def parse; end

        # Code `{#prase}` and a hash {a: 1} are not links
        def call; end
      end
    RUBY

    assert_empty(offenses)
  end

  it 'ignores links inside indented code blocks' do
    offenses = offenses_for(<<~RUBY)
      # App
      module ReferenceApp
        # Worker
        class Worker
          # Example:
          #
          #     opts = {Wroker => 1}
          def call; end
        end
      end
    RUBY

    assert_empty(offenses)
  end

  it 'checks links on continuation lines of a tag' do
    messages = messages_for(<<~RUBY)
      # Parser
      class ReferenceParser
        # Parses
        def parse; end

        # Calls
        # @param input [String] passed on
        #   to {#prase}
        def call(input); end
      end
    RUBY

    assert_equal(["Reference '#prase' does not resolve (did you mean '#parse'?)"], messages)
  end

  it 'does not flag a name with no close match' do
    offenses = offenses_for(<<~RUBY)
      # Parser
      class ReferenceParser
        # Parses
        def parse; end

        # See {#completely_unrelated}
        def call; end
      end
    RUBY

    assert_empty(offenses)
  end

  it 'can be disabled' do
    path = File.join(dir, 'example.rb')
    File.write(path, <<~RUBY)
      # Parser
      class ReferenceParser
        # Parses
        def parse; end

        # Delegates to {#prase}
        def call; end
      end
    RUBY

    config = test_config { |c| c.set_validator_config('Documentation/ReferenceTypo', 'Enabled', false) }
    offenses = Yard::Lint.run(path: path, config: config, progress: false).offenses

    assert_empty(offenses.select { |offense| offense[:validator] == 'Documentation/ReferenceTypo' })
  end
end

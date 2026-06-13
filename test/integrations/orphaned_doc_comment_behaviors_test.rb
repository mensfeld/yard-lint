# frozen_string_literal: true

# Characterization suite for Documentation/OrphanedDocComment.
#
# These tests pin down the validator's CORRECT behaviour across a broad range
# of Ruby constructs so that an internal rewrite (e.g. switching the comment
# scanner from line regexes to a token-based scan) can be proven not to change
# any of them. Every case here passes against the current implementation; the
# only intended behaviour change of the rewrite is fixing the heredoc/string
# false positives (BUG-035), which are covered separately.
describe 'Documentation/OrphanedDocComment behaviours' do
  attr_reader :config, :tmpdir

  before do
    @tmpdir = Dir.mktmpdir
    @config = test_config do |c|
      c.set_validator_config('Documentation/OrphanedDocComment', 'Enabled', true)
    end
  end

  after do
    FileUtils.rm_rf(@tmpdir)
  end

  def write_file(content)
    path = File.join(@tmpdir, 'test.rb')
    File.write(path, content)
    path
  end

  def offenses_for(content)
    path = write_file(content)
    result = Yard::Lint.run(path: path, config: config, progress: false)
    result.offenses.select { |o| o[:name] == 'OrphanedDocComment' }
  end

  def assert_clean(content)
    assert_empty(offenses_for(content))
  end

  def assert_orphaned(content, count: 1)
    offenses = offenses_for(content)
    assert_equal(count, offenses.count, "expected #{count} orphaned offense(s)")
  end

  # ------------------------------------------------------------------
  # Valid attachments: YARD attaches the docstring, so NOT orphaned.
  # ------------------------------------------------------------------

  describe 'definitions YARD documents (not orphaned)' do
    it 'does not flag a comment before a namespaced constant assignment' do
      assert_clean(<<~RUBY)
        # @return [Integer] the limit
        Foo::MAX = 100
      RUBY
    end

    it 'does not flag a comment before a namespaced module' do
      assert_clean(<<~RUBY)
        # @return [void] namespaced module
        module Foo::Bar
        end
      RUBY
    end

    it 'does not flag a comment before attr_internal' do
      assert_clean(<<~RUBY)
        class Counter
          # @return [Integer] internal count
          attr_internal :count
        end
      RUBY
    end

    it 'does not flag a comment before define_method with a block' do
      assert_clean(<<~RUBY)
        class C
          # @return [void] dynamically defined
          define_method(:foo) do
          end
        end
      RUBY
    end

    it 'does not flag a deeply nested, indented definition' do
      assert_clean(<<~RUBY)
        module M
          class C
            # @param x [Integer] a number
            def foo(x); end
          end
        end
      RUBY
    end

    it 'does not flag a comment before a multiline method signature' do
      assert_clean(<<~RUBY)
        # @param a [Integer] first
        # @param b [Integer] second
        def add(
          a,
          b
        )
          a + b
        end
      RUBY
    end
  end

  # ------------------------------------------------------------------
  # DSL constructs the handler turns into documentable objects.
  # ------------------------------------------------------------------

  describe 'DSL calls (not orphaned)' do
    it 'does not flag a comment before a scope with a lambda argument' do
      assert_clean(<<~RUBY)
        class C
          # @return [void] active scope
          scope :active, -> { where(active: true) }
        end
      RUBY
    end

    it 'does not flag a comment before a receiver DSL call carrying a @method tag' do
      assert_clean(<<~RUBY)
        # @method dynamic_size
        # @return [Integer] size
        MyDSL.register :size do
        end
      RUBY
    end

    it 'does not flag a comment before a call carrying an @attribute tag' do
      assert_clean(<<~RUBY)
        # @attribute size
        # @return [Integer] size
        acts_as_thing do
        end
      RUBY
    end

    it 'does not flag a comment before a wrapped def (memoize def)' do
      assert_clean(<<~RUBY)
        # @return [String] the value
        memoize def value
          "computed"
        end
      RUBY
    end

    it 'does not flag a comment before module_function def' do
      assert_clean(<<~RUBY)
        module M
          # @return [void] helper
          module_function def helper
          end
        end
      RUBY
    end
  end

  # ------------------------------------------------------------------
  # Comment blocks that carry no real YARD tag, or are directives,
  # or are magic comments: never orphaned.
  # ------------------------------------------------------------------

  describe 'non-tag comment blocks (not orphaned)' do
    it 'does not flag a tag mentioned mid-line in prose' do
      assert_clean(<<~RUBY)
        # This paragraph mentions @param somewhere in the middle.
        x = 1
        def m; end
      RUBY
    end

    it 'does not flag an instance-variable reference that looks like a tag' do
      assert_clean(<<~RUBY)
        # @body.each iterates over the buffer contents.
        x = 1
        def m; end
      RUBY
    end

    it 'does not flag a plain comment with no YARD tags' do
      assert_clean(<<~RUBY)
        # just an ordinary explanatory comment
        x = 1
        def m; end
      RUBY
    end

    it 'does not flag a @!parse directive block' do
      assert_clean(<<~RUBY)
        # @!parse
        #   def generated; end
        x = 1
        def m; end
      RUBY
    end
  end

  # ------------------------------------------------------------------
  # Magic comments and magic-comment-like prose (BUG-245 territory).
  # ------------------------------------------------------------------

  describe 'magic comments (not orphaned)' do
    it 'does not treat an encoding magic comment as a tagged block' do
      assert_clean(<<~RUBY)
        # encoding: UTF-8
        # @param x [Integer] a number
        def m(x); end
      RUBY
    end

    it 'does not split a block on magic-comment-like prose' do
      assert_clean(<<~RUBY)
        # encoding: UTF-8 is assumed for all inputs here
        # @param x [Integer] a number
        def m(x); end
      RUBY
    end

    it 'does not treat a warn_indent magic comment as a tagged block' do
      assert_clean(<<~RUBY)
        # warn_indent: true
        # @param x [Integer] a number
        def m(x); end
      RUBY
    end

    it 'does not treat a shareable_constant_value magic comment as a tagged block' do
      assert_clean(<<~RUBY)
        # shareable_constant_value: literal
        # @param x [Integer] a number
        def m(x); end
      RUBY
    end
  end

  # ------------------------------------------------------------------
  # Genuinely orphaned: YARD drops the docstring, so MUST flag.
  # ------------------------------------------------------------------

  describe 'genuinely orphaned comments (flagged)' do
    it 'flags a comment before an instance-variable assignment' do
      assert_orphaned(<<~RUBY)
        class C
          # @return [Integer] cached
          @cached = compute
        end
      RUBY
    end

    it 'flags a comment before a multiple assignment' do
      assert_orphaned(<<~RUBY)
        # @return [void] orphaned
        a, b = 1, 2

        def real; end
      RUBY
    end

    it 'flags a comment before a return statement' do
      assert_orphaned(<<~RUBY)
        class C
          def a
            # @return [Integer] orphaned
            return 1
          end
        end
      RUBY
    end

    it 'flags a comment before a plain method call' do
      assert_orphaned(<<~RUBY)
        # @param x [Integer] orphaned
        log_something(x)

        def real(x); end
      RUBY
    end

    it 'flags a comment before an if statement' do
      assert_orphaned(<<~RUBY)
        # @return [void] orphaned
        if condition
        end

        def real; end
      RUBY
    end

    it 'flags a comment before a while loop' do
      assert_orphaned(<<~RUBY)
        class C
          def a
            # @return [void] orphaned
            while running
            end
          end
        end
      RUBY
    end

    it 'flags a comment before a yield' do
      assert_orphaned(<<~RUBY)
        class C
          def a
            # @return [void] orphaned
            yield
          end
        end
      RUBY
    end

    it 'flags a comment before a raise' do
      assert_orphaned(<<~RUBY)
        class C
          def a
            # @return [void] orphaned
            raise ArgumentError
          end
        end
      RUBY
    end

    it 'flags a comment before a bare string statement' do
      assert_orphaned(<<~RUBY)
        # @return [String] orphaned
        "just a string"

        def real; end
      RUBY
    end

    it 'reports the start line of the orphaned block' do
      offenses = offenses_for(<<~RUBY)
        # @param x [Integer] orphaned
        # @return [void]
        x = 1

        def real(x); end
      RUBY
      assert_equal(1, offenses.count)
      assert_equal(1, offenses.first[:location_line])
    end

    it 'flags each of several orphaned blocks independently' do
      assert_orphaned(<<~RUBY, count: 2)
        # @param a [Integer] first orphan
        x = 1

        def documented(a); end

        # @return [void] second orphan
        y = 2

        def also_documented; end
      RUBY
    end
  end
end

# frozen_string_literal: true

# BUG-035: OrphanedDocComment must not treat heredoc / string-literal content
# as Ruby comments. A line that merely begins with '#' inside a heredoc or a
# multi-line string is data, not a documentation comment, so a YARD-tag-looking
# line there must never be reported as orphaned.
describe 'Documentation/OrphanedDocComment heredoc and string content' do
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

  def offenses_for(content)
    path = File.join(@tmpdir, 'test.rb')
    File.write(path, content)
    result = Yard::Lint.run(path: path, config: config, progress: false)
    result.offenses.select { |o| o[:name] == 'OrphanedDocComment' }
  end

  it 'does not flag a tag-looking line inside a squiggly heredoc' do
    assert_empty(offenses_for(<<~'RUBY'))
      class C
        def template
          <<~SQL
            SELECT 1
            # @param x [Integer] not a real comment
            FROM t
          SQL
        end

        # @param x [Integer] the real one
        def real(x); end
      end
    RUBY
  end

  it 'does not flag a tag-looking line inside a heredoc assigned to a constant' do
    assert_empty(offenses_for(<<~'RUBY'))
      TEMPLATE = <<~TEXT
        # @param x [Integer] inside heredoc, not a comment
        done
      TEXT
    RUBY
  end

  it 'does not flag a tag-looking line inside a dash heredoc' do
    assert_empty(offenses_for(<<~'RUBY'))
      class C
        def sql
          <<-SQL
          # @return [void] heredoc body
          SELECT 1
          SQL
        end
      end
    RUBY
  end

  it 'does not flag a tag-looking line inside a multi-line string literal' do
    assert_empty(offenses_for(<<~'RUBY'))
      class C
        def banner
          "
          # @param x [Integer] inside a string
          "
        end
      end
    RUBY
  end

  it 'still flags a genuinely orphaned comment in a file that also contains a heredoc' do
    offenses = offenses_for(<<~'RUBY')
      class C
        def template
          <<~SQL
            # @param x [Integer] not a comment
            SELECT 1
          SQL
        end
      end

      # @return [void] genuinely orphaned
      orphan_call

      def real; end
    RUBY
    assert_equal(1, offenses.count)
    assert_includes(offenses.first[:message], '@return')
  end

  it 'still attaches a real doc comment that follows a heredoc method' do
    assert_empty(offenses_for(<<~'RUBY'))
      class C
        def sql
          <<~SQL
            # @param ignored [Integer] heredoc content
            SELECT 1
          SQL
        end

        # @param y [Integer] the value
        def real(y); end
      end
    RUBY
  end
end

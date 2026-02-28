# frozen_string_literal: true

require 'tempfile'
require 'test_helper'

class BlankLinesWithinDocsTest < Minitest::Test
  attr_reader :config

  def setup
    @config = test_config do |c|
      c.send(:set_validator_config, 'Documentation/BlankLineBeforeDefinition', 'Enabled', true)
    end
  end

  def test_correctly_counts_only_blank_lines_after_the_last_doc_comment
    fixture = Tempfile.new(['method_internal_blanks', '.rb'])
    fixture.write(<<~RUBY)
      # frozen_string_literal: true

      # Method with blank line within docs
      # @param organization_id [String]
      # @param id [String]
      #
      # @return [Pet]

      def call_single_blank(organization_id, id)
        "\#{organization_id} - \#{id}"
      end

      # Method with blank line within docs and TWO blanks after
      # @param organization_id [String]
      # @param id [String]
      #
      # @return [Pet]


      def call_two_blanks(organization_id, id)
        "\#{organization_id} - \#{id}"
      end

      # Method with blank line within docs and THREE blanks after
      # @param organization_id [String]
      # @param id [String]
      #
      # @return [Pet]



      def call_three_blanks(organization_id, id)
        "\#{organization_id} - \#{id}"
      end

      # Method with NO blank line after docs (even though blank within)
      # @param organization_id [String]
      # @param id [String]
      #
      # @return [Pet]
      def call_valid(organization_id, id)
        "\#{organization_id} - \#{id}"
      end
    RUBY
    fixture.close

    result = Yard::Lint.run(path: fixture.path, config: config, progress: false)

    offenses = result.offenses.select { |o| o[:name] == 'BlankLineBeforeDefinition' }

    # Should find 3 violations (not 4, since call_valid is properly formatted)
    assert_equal(3, offenses.size)

    # Check single blank line violation
    single_offense = offenses.find { |o| o[:message].include?('call_single_blank') }
    refute_nil(single_offense)
    assert_includes(single_offense[:message], 'Blank line between documentation and definition')
    refute_includes(single_offense[:message], 'orphaned')

    # Check two blank lines (orphaned)
    two_blank_offense = offenses.find { |o| o[:message].include?('call_two_blanks') }
    refute_nil(two_blank_offense)
    assert_includes(two_blank_offense[:message], 'orphaned')
    assert_includes(two_blank_offense[:message], '2 blank lines')

    # Check three blank lines (orphaned)
    three_blank_offense = offenses.find { |o| o[:message].include?('call_three_blanks') }
    refute_nil(three_blank_offense)
    assert_includes(three_blank_offense[:message], 'orphaned')
    assert_includes(three_blank_offense[:message], '3 blank lines')

    # Verify call_valid is NOT flagged
    valid_offense = offenses.find { |o| o[:message].include?('call_valid') }
    assert_nil(valid_offense)

    fixture.unlink
  end

  def test_handles_multiple_consecutive_blank_lines_within_documentation
    fixture = Tempfile.new(['multi_internal_blanks', '.rb'])
    fixture.write(<<~RUBY)
      # frozen_string_literal: true

      # Method description
      #
      #
      # @param value [String]
      #
      #
      # @return [Boolean]

      def process(value)
        true
      end
    RUBY
    fixture.close

    result = Yard::Lint.run(path: fixture.path, config: config, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'BlankLineBeforeDefinition' &&
        o[:message].include?('process')
    end

    # Should detect single blank line after the last doc line
    assert_equal(1, offenses.size)
    assert_includes(offenses.first[:message], 'Blank line between documentation and definition')
    refute_includes(offenses.first[:message], 'orphaned')

    fixture.unlink
  end

  def test_detects_blank_lines_after_class_documentation
    fixture = Tempfile.new(['class_blanks', '.rb'])
    fixture.write(<<~RUBY)
      # frozen_string_literal: true

      # User authentication handler
      # @example
      #   AuthHandler.new
      #
      # @note This is a note

      class AuthHandlerSingleBlank
      end

      # User authentication handler
      # @example
      #   AuthHandler.new
      #
      # @note This is a note


      class AuthHandlerTwoBlanks
      end

      # User authentication handler
      # @example
      #   AuthHandler.new
      #
      # @note This is a note
      class AuthHandlerValid
      end
    RUBY
    fixture.close

    result = Yard::Lint.run(path: fixture.path, config: config, progress: false)

    offenses = result.offenses.select { |o| o[:name] == 'BlankLineBeforeDefinition' }

    # Should find 2 violations
    assert_equal(2, offenses.size)

    single_offense = offenses.find { |o| o[:message].include?('AuthHandlerSingleBlank') }
    refute_nil(single_offense)

    two_offense = offenses.find { |o| o[:message].include?('AuthHandlerTwoBlanks') }
    refute_nil(two_offense)
    assert_includes(two_offense[:message], 'orphaned')

    fixture.unlink
  end

  def test_detects_blank_lines_after_module_documentation
    fixture = Tempfile.new(['module_blanks', '.rb'])
    fixture.write(<<~RUBY)
      # frozen_string_literal: true

      # Validation helpers
      # @example
      #   Validators.call
      #
      # @since 1.0.0

      module ValidatorsSingleBlank
      end

      # Validation helpers
      # @example
      #   Validators.call
      #
      # @since 1.0.0



      module ValidatorsThreeBlanks
      end

      # Validation helpers
      # @example
      #   Validators.call
      #
      # @since 1.0.0
      module ValidatorsValid
      end
    RUBY
    fixture.close

    result = Yard::Lint.run(path: fixture.path, config: config, progress: false)

    offenses = result.offenses.select { |o| o[:name] == 'BlankLineBeforeDefinition' }

    # Should find 2 violations
    assert_equal(2, offenses.size)

    single_offense = offenses.find { |o| o[:message].include?('ValidatorsSingleBlank') }
    refute_nil(single_offense)

    three_offense = offenses.find { |o| o[:message].include?('ValidatorsThreeBlanks') }
    refute_nil(three_offense)
    assert_includes(three_offense[:message], 'orphaned')
    assert_includes(three_offense[:message], '3 blank lines')

    fixture.unlink
  end

  def test_detects_blank_lines_after_constant_documentation
    fixture = Tempfile.new(['constant_blanks', '.rb'])
    fixture.write(<<~RUBY)
      # frozen_string_literal: true

      class Container
        # Default configuration
        # @return [Hash]
        #
        # @note Can be overridden

        DEFAULT_CONFIG = {}.freeze

        # Maximum retries
        # @return [Integer]
        #
        # @note Upper bound


        MAX_RETRIES = 3

        # Timeout value
        # @return [Integer]
        #
        # @note In seconds
        TIMEOUT = 30
      end
    RUBY
    fixture.close

    result = Yard::Lint.run(path: fixture.path, config: config, progress: false)

    offenses = result.offenses.select { |o| o[:name] == 'BlankLineBeforeDefinition' }

    # Should find violations for DEFAULT_CONFIG and MAX_RETRIES
    # (but not TIMEOUT which is properly formatted)
    # Note: Container class has no documentation so won't be flagged
    assert_equal(2, offenses.size)

    default_config_offense = offenses.find { |o| o[:message].include?('DEFAULT_CONFIG') }
    refute_nil(default_config_offense)
    assert_includes(default_config_offense[:message], 'Blank line between documentation')

    max_retries_offense = offenses.find { |o| o[:message].include?('MAX_RETRIES') }
    refute_nil(max_retries_offense)
    assert_includes(max_retries_offense[:message], 'orphaned')

    fixture.unlink
  end

  def test_handles_magic_comments_with_blank_lines_in_docs_correctly
    fixture = Tempfile.new(['magic_with_doc_blanks', '.rb'])
    fixture.write(<<~RUBY)
      # frozen_string_literal: true
      # encoding: utf-8

      # Process user data
      # @param user [Hash]
      #
      # @return [User]

      class UserProcessor
        # Validate user
        # @param data [Hash]
        #
        # @return [Boolean]


        def validate(data)
          true
        end
      end
    RUBY
    fixture.close

    result = Yard::Lint.run(path: fixture.path, config: config, progress: false)

    offenses = result.offenses.select { |o| o[:name] == 'BlankLineBeforeDefinition' }

    # Should find 2 violations: UserProcessor class (1 blank) and validate method (2 blanks)
    assert_equal(2, offenses.size)

    class_offense = offenses.find { |o| o[:message].include?('UserProcessor') }
    refute_nil(class_offense)
    assert_includes(class_offense[:message], 'Blank line between documentation')

    method_offense = offenses.find { |o| o[:message].include?('validate') }
    refute_nil(method_offense)
    assert_includes(method_offense[:message], 'orphaned')
    assert_includes(method_offense[:message], '2 blank lines')

    fixture.unlink
  end

  def test_handles_documentation_with_only_blank_lines_no_tags
    fixture = Tempfile.new(['simple_doc_blanks', '.rb'])
    fixture.write(<<~RUBY)
      # frozen_string_literal: true

      # Simple description

      def simple_single
        'value'
      end

      # Another description


      def simple_orphaned
        'value'
      end
    RUBY
    fixture.close

    result = Yard::Lint.run(path: fixture.path, config: config, progress: false)

    offenses = result.offenses.select { |o| o[:name] == 'BlankLineBeforeDefinition' }

    assert_equal(2, offenses.size)

    single_offense = offenses.find { |o| o[:message].include?('simple_single') }
    refute_nil(single_offense)

    orphaned_offense = offenses.find { |o| o[:message].include?('simple_orphaned') }
    refute_nil(orphaned_offense)
    assert_includes(orphaned_offense[:message], 'orphaned')

    fixture.unlink
  end

  def test_does_not_count_comment_only_lines_within_docs_as_blanks
    fixture = Tempfile.new(['comment_separator', '.rb'])
    fixture.write(<<~RUBY)
      # frozen_string_literal: true

      # Method description
      #
      # More details here
      def no_blank_after
        'value'
      end
    RUBY
    fixture.close

    result = Yard::Lint.run(path: fixture.path, config: config, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'BlankLineBeforeDefinition' &&
        o[:message].include?('no_blank_after')
    end

    # Should NOT flag - no blank line between last comment and def
    assert_empty(offenses)

    fixture.unlink
  end
end

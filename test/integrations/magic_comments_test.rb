# frozen_string_literal: true

require 'test_helper'

class BlanklinebeforedefinitionWithMagicCommentsTest < Minitest::Test
  attr_reader :config, :fixture_path

  def setup
    @fixture_path = File.expand_path('../fixtures/magic_comments.rb', __dir__)
    @config = test_config do |c|
    c.send(:set_validator_config, 'Documentation/BlankLineBeforeDefinition', 'Enabled', true)
    end
  end

  def test_handling_ruby_magic_comments_does_not_treat_frozen_string_literal_as_yard_documentation
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'BlankLineBeforeDefinition' &&
        o[:message].include?('MagicCommentsExamples')
        end
    # Should not flag the class because frozen_string_literal is not YARD documentation
    assert_empty(offenses)
  end

  def test_handling_ruby_magic_comments_does_not_treat_encoding_comments_as_yard_documentation
    encoding_fixture = Tempfile.new(['encoding_test', '.rb'])
    encoding_fixture.write(<<~RUBY)
      # encoding: utf-8

      class EncodingTest
        def foo
          'bar'
          end
      end
    RUBY
    encoding_fixture.close

    result = Yard::Lint.run(path: encoding_fixture.path, config: config, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'BlankLineBeforeDefinition' &&
        o[:message].include?('EncodingTest')
        end
    assert_empty(offenses)

    encoding_fixture.unlink
  end

  def test_handling_ruby_magic_comments_does_not_treat_warn_indent_comments_as_yard_documentation
    warn_indent_fixture = Tempfile.new(['warn_indent_test', '.rb'])
    warn_indent_fixture.write(<<~RUBY)
      # warn_indent: true

      class WarnIndentTest
        def foo
          'bar'
          end
      end
    RUBY
    warn_indent_fixture.close

    result = Yard::Lint.run(path: warn_indent_fixture.path, config: config, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'BlankLineBeforeDefinition' &&
        o[:message].include?('WarnIndentTest')
        end
    assert_empty(offenses)

    warn_indent_fixture.unlink
  end

  def test_handling_ruby_magic_comments_does_not_treat_shareable_constant_value_comments_as_yard_documenta
    shareable_fixture = Tempfile.new(['shareable_test', '.rb'])
    shareable_fixture.write(<<~RUBY)
      # shareable_constant_value: literal

      class ShareableTest
        def foo
          'bar'
          end
      end
    RUBY
    shareable_fixture.close

    result = Yard::Lint.run(path: shareable_fixture.path, config: config, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'BlankLineBeforeDefinition' &&
        o[:message].include?('ShareableTest')
        end
    assert_empty(offenses)

    shareable_fixture.unlink
  end

  def test_handling_ruby_magic_comments_still_detects_real_yard_docs_with_blank_lines_even_when_magic_comm
    yard_with_magic_fixture = Tempfile.new(['yard_with_magic', '.rb'])
    yard_with_magic_fixture.write(<<~RUBY)
      # frozen_string_literal: true

      # This is YARD documentation
      # @example Usage
      #   YardWithMagic.new

      class YardWithMagic

      end
    RUBY
    yard_with_magic_fixture.close

    result = Yard::Lint.run(path: yard_with_magic_fixture.path, config: config, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'BlankLineBeforeDefinition' &&
        o[:message].include?('YardWithMagic')
        end
    # Should detect the single blank line between YARD docs and class definition
    assert_equal(1, offenses.size)
    assert_includes(offenses.first[:message], 'Blank line between documentation and definition')
    yard_with_magic_fixture.unlink
  end

  def test_handling_ruby_magic_comments_correctly_handles_multiple_magic_comments
    multiple_magic_fixture = Tempfile.new(['multiple_magic', '.rb'])
    multiple_magic_fixture.write(<<~RUBY)
      # frozen_string_literal: true
      # encoding: utf-8

      class MultipleMagic
        def foo
          'bar'
          end
      end
    RUBY
    multiple_magic_fixture.close

    result = Yard::Lint.run(path: multiple_magic_fixture.path, config: config, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'BlankLineBeforeDefinition' &&
        o[:message].include?('MultipleMagic')
        end
    # Should not flag - magic comments are not YARD docs
    assert_empty(offenses)

    multiple_magic_fixture.unlink
  end

  def test_handling_ruby_magic_comments_handles_magic_comments_with_different_spacing_variations
    spacing_variations_fixture = Tempfile.new(['spacing_variations', '.rb'])
    spacing_variations_fixture.write(<<~RUBY)
      #frozen_string_literal:true

      class SpacingVariations
        def foo
          'bar'
          end
      end
    RUBY
    spacing_variations_fixture.close

    result = Yard::Lint.run(path: spacing_variations_fixture.path, config: config, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'BlankLineBeforeDefinition' &&
        o[:message].include?('SpacingVariations')
        end
    # Should not flag - magic comments regardless of spacing
    assert_empty(offenses)

    spacing_variations_fixture.unlink
  end

  def test_real_world_migration_file_example_does_not_flag_migration_files_with_only_magic_comments
    migration_fixture = Tempfile.new(['migration_test', '.rb'])
    migration_fixture.write(<<~RUBY)
      # frozen_string_literal: true

      class AddLevelToTags < ActiveRecord::Migration[8.0]
        def change
          add_column(:tags, :level, :string, array: true, default: EMPTY_ARRAY)
          Tag.update_all(level: %w[pet])
          change_column_null(:tags, :level, false)
          end
      end
    RUBY
    migration_fixture.close

    result = Yard::Lint.run(path: migration_fixture.path, config: config, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'BlankLineBeforeDefinition' &&
        o[:message].include?('AddLevelToTags')
        end
    # Should not flag - frozen_string_literal is not YARD documentation
    assert_empty(offenses)

    migration_fixture.unlink
  end

  def test_magic_comments_with_yard_documentation_detects_blank_line_between_yard_docs_and_code_when_magic
    combined_fixture = Tempfile.new(['combined_test', '.rb'])
    combined_fixture.write(<<~RUBY)
      # frozen_string_literal: true

      # This class handles user authentication
      # @example
      #   AuthHandler.new

      class AuthHandler
        # Validates user credentials
        # @param username [String] the username
        # @return [Boolean] whether valid

        def validate(username)
          true
          end
      end
    RUBY
    combined_fixture.close

    result = Yard::Lint.run(path: combined_fixture.path, config: config, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'BlankLineBeforeDefinition'
      end
    # Should find 2 violations: one for the class, one for the method
    assert_equal(2, offenses.size)
    class_offense = offenses.find { |o| o[:message].include?('AuthHandler') && !o[:message].include?('validate') }
    method_offense = offenses.find { |o| o[:message].include?('validate') }

    refute_nil(class_offense)
    assert_includes(class_offense[:message], 'Blank line between documentation and definition')
    refute_nil(method_offense)
    assert_includes(method_offense[:message], 'Blank line between documentation and definition')
    combined_fixture.unlink
  end

  def test_magic_comments_with_yard_documentation_does_not_flag_when_magic_comment_yard_docs_and_code_are_
    proper_fixture = Tempfile.new(['proper_test', '.rb'])
    proper_fixture.write(<<~RUBY)
      # frozen_string_literal: true

      # This class handles user authentication
      # @example
      #   AuthHandler.new
      class AuthHandler
        # Validates user credentials
        # @param username [String] the username
        # @return [Boolean] whether valid
        def validate(username)
          true
          end
      end
    RUBY
    proper_fixture.close

    result = Yard::Lint.run(path: proper_fixture.path, config: config, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'BlankLineBeforeDefinition'
      end
    # Should not flag anything - no blank lines between YARD docs and definitions
    assert_empty(offenses)

    proper_fixture.unlink
  end

  def test_magic_comments_with_yard_documentation_handles_orphaned_docs_2_blank_lines_with_magic_comments_
    orphaned_fixture = Tempfile.new(['orphaned_test', '.rb'])
    orphaned_fixture.write(<<~RUBY)
      # frozen_string_literal: true
      # encoding: utf-8

      # This class is orphaned
      # @example
      #   OrphanedClass.new


      class OrphanedClass
        # This method is orphaned too
        # @param value [String] the value


        def process(value)
          value.upcase
          end
      end
    RUBY
    orphaned_fixture.close

    result = Yard::Lint.run(path: orphaned_fixture.path, config: config, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'BlankLineBeforeDefinition'
      end
    # Should find 2 orphaned documentation violations
    assert_equal(2, offenses.size)
    offenses.each do |offense|
      assert_includes(offense[:message], 'orphaned')
      end
    orphaned_fixture.unlink
  end
end


# frozen_string_literal: true

RSpec.describe 'BlankLineBeforeDefinition with Magic Comments' do
  let(:fixture_path) { File.expand_path('../fixtures/magic_comments.rb', __dir__) }

  let(:config) do
    test_config do |c|
      c.send(:set_validator_config, 'Documentation/BlankLineBeforeDefinition', 'Enabled', true)
    end
  end

  describe 'handling Ruby magic comments' do
    it 'does not treat frozen_string_literal as YARD documentation' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offenses = result.offenses.select do |o|
        o[:name] == 'BlankLineBeforeDefinition' &&
          o[:message].include?('MagicCommentsExamples')
      end

      # Should not flag the class because frozen_string_literal is not YARD documentation
      expect(offenses).to be_empty
    end

    it 'does not treat encoding comments as YARD documentation' do
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

      expect(offenses).to be_empty

      encoding_fixture.unlink
    end

    it 'does not treat warn_indent comments as YARD documentation' do
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

      expect(offenses).to be_empty

      warn_indent_fixture.unlink
    end

    it 'does not treat shareable_constant_value comments as YARD documentation' do
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

      expect(offenses).to be_empty

      shareable_fixture.unlink
    end

    it 'still detects real YARD docs with blank lines even when magic comments present' do
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
      expect(offenses.size).to eq(1)
      expect(offenses.first[:message]).to include('Blank line between documentation and definition')

      yard_with_magic_fixture.unlink
    end

    it 'correctly handles multiple magic comments' do
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
      expect(offenses).to be_empty

      multiple_magic_fixture.unlink
    end

    it 'handles magic comments with different spacing variations' do
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
      expect(offenses).to be_empty

      spacing_variations_fixture.unlink
    end
  end

  describe 'real-world migration file example' do
    it 'does not flag migration files with only magic comments' do
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
      expect(offenses).to be_empty

      migration_fixture.unlink
    end
  end

  describe 'magic comments with YARD documentation' do
    it 'detects blank line between YARD docs and code when magic comment is present' do
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
      expect(offenses.size).to eq(2)

      class_offense = offenses.find { |o| o[:message].include?('AuthHandler') && !o[:message].include?('validate') }
      method_offense = offenses.find { |o| o[:message].include?('validate') }

      expect(class_offense).not_to be_nil
      expect(class_offense[:message]).to include('Blank line between documentation and definition')

      expect(method_offense).not_to be_nil
      expect(method_offense[:message]).to include('Blank line between documentation and definition')

      combined_fixture.unlink
    end

    it 'does not flag when magic comment, YARD docs, and code are properly adjacent' do
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
      expect(offenses).to be_empty

      proper_fixture.unlink
    end

    it 'handles orphaned docs (2+ blank lines) with magic comments present' do
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
      expect(offenses.size).to eq(2)

      offenses.each do |offense|
        expect(offense[:message]).to include('orphaned')
      end

      orphaned_fixture.unlink
    end
  end
end

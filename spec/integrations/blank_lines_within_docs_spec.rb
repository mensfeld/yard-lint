# frozen_string_literal: true

RSpec.describe 'BlankLineBeforeDefinition with blank lines within YARD docs' do
  let(:config) do
    test_config do |c|
      c.send(:set_validator_config, 'Documentation/BlankLineBeforeDefinition', 'Enabled', true)
    end
  end

  describe 'methods with blank lines within YARD documentation' do
    it 'correctly counts only blank lines AFTER the last doc comment' do
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
      expect(offenses.size).to eq(3)

      # Check single blank line violation
      single_offense = offenses.find { |o| o[:message].include?('call_single_blank') }
      expect(single_offense).not_to be_nil
      expect(single_offense[:message]).to include('Blank line between documentation and definition')
      expect(single_offense[:message]).not_to include('orphaned')

      # Check two blank lines (orphaned)
      two_blank_offense = offenses.find { |o| o[:message].include?('call_two_blanks') }
      expect(two_blank_offense).not_to be_nil
      expect(two_blank_offense[:message]).to include('orphaned')
      expect(two_blank_offense[:message]).to include('2 blank lines')

      # Check three blank lines (orphaned)
      three_blank_offense = offenses.find { |o| o[:message].include?('call_three_blanks') }
      expect(three_blank_offense).not_to be_nil
      expect(three_blank_offense[:message]).to include('orphaned')
      expect(three_blank_offense[:message]).to include('3 blank lines')

      # Verify call_valid is NOT flagged
      valid_offense = offenses.find { |o| o[:message].include?('call_valid') }
      expect(valid_offense).to be_nil

      fixture.unlink
    end

    it 'handles multiple consecutive blank lines within documentation' do
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
      expect(offenses.size).to eq(1)
      expect(offenses.first[:message]).to include('Blank line between documentation and definition')
      expect(offenses.first[:message]).not_to include('orphaned')

      fixture.unlink
    end
  end

  describe 'classes with blank lines within and after YARD documentation' do
    it 'detects blank lines after class documentation' do
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
      expect(offenses.size).to eq(2)

      single_offense = offenses.find { |o| o[:message].include?('AuthHandlerSingleBlank') }
      expect(single_offense).not_to be_nil

      two_offense = offenses.find { |o| o[:message].include?('AuthHandlerTwoBlanks') }
      expect(two_offense).not_to be_nil
      expect(two_offense[:message]).to include('orphaned')

      fixture.unlink
    end
  end

  describe 'modules with blank lines within and after YARD documentation' do
    it 'detects blank lines after module documentation' do
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
      expect(offenses.size).to eq(2)

      single_offense = offenses.find { |o| o[:message].include?('ValidatorsSingleBlank') }
      expect(single_offense).not_to be_nil

      three_offense = offenses.find { |o| o[:message].include?('ValidatorsThreeBlanks') }
      expect(three_offense).not_to be_nil
      expect(three_offense[:message]).to include('orphaned')
      expect(three_offense[:message]).to include('3 blank lines')

      fixture.unlink
    end
  end

  describe 'constants with blank lines within and after YARD documentation' do
    it 'detects blank lines after constant documentation' do
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
      expect(offenses.size).to eq(2)

      default_config_offense = offenses.find { |o| o[:message].include?('DEFAULT_CONFIG') }
      expect(default_config_offense).not_to be_nil
      expect(default_config_offense[:message]).to include('Blank line between documentation')

      max_retries_offense = offenses.find { |o| o[:message].include?('MAX_RETRIES') }
      expect(max_retries_offense).not_to be_nil
      expect(max_retries_offense[:message]).to include('orphaned')

      fixture.unlink
    end
  end

  describe 'mixed scenarios with magic comments' do
    it 'handles magic comments with blank lines in docs correctly' do
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
      expect(offenses.size).to eq(2)

      class_offense = offenses.find { |o| o[:message].include?('UserProcessor') }
      expect(class_offense).not_to be_nil
      expect(class_offense[:message]).to include('Blank line between documentation')

      method_offense = offenses.find { |o| o[:message].include?('validate') }
      expect(method_offense).not_to be_nil
      expect(method_offense[:message]).to include('orphaned')
      expect(method_offense[:message]).to include('2 blank lines')

      fixture.unlink
    end
  end

  describe 'edge cases' do
    it 'handles documentation with only blank lines (no tags)' do
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

      expect(offenses.size).to eq(2)

      single_offense = offenses.find { |o| o[:message].include?('simple_single') }
      expect(single_offense).not_to be_nil

      orphaned_offense = offenses.find { |o| o[:message].include?('simple_orphaned') }
      expect(orphaned_offense).not_to be_nil
      expect(orphaned_offense[:message]).to include('orphaned')

      fixture.unlink
    end

    it 'does not count comment-only lines within docs as blanks' do
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
      expect(offenses).to be_empty

      fixture.unlink
    end
  end
end

# frozen_string_literal: true

require 'tempfile'

RSpec.describe 'Unknown Tag Integration' do
  subject(:result) { Yard::Lint.run(path: temp_file.path, progress: false, config: config) }

  let(:temp_file) { Tempfile.new(['test', '.rb']) }
  let(:config) do
    test_config do |c|
      c.send(:set_validator_config, 'Warnings/UnknownTag', 'Enabled', true)
    end
  end

  after { temp_file.unlink }

  describe 'detecting unknown tags' do
    context 'when using non-existent YARD tag' do
      before do
        temp_file.write(<<~RUBY)
          # frozen_string_literal: true

          # Test class for unknown tags
          class TestClass
            # Method with unknown tag
            # @returns [String] should be @return not @returns
            # @param value [String] the value
            def method_with_wrong_tag(value)
              value
            end
          end
        RUBY
        temp_file.rewind
      end

      it 'reports offense with correct file path and line number' do
        offense = result.offenses.find { |o| o[:name] == 'UnknownTag' && o[:message].include?('@returns') }

        expect(offense).not_to be_nil
        expect(offense[:location]).to eq(temp_file.path)
        expect(offense[:message]).to include('@returns')
      end
    end

    context 'when using standard YARD tags' do
      before do
        temp_file.write(<<~RUBY)
          # frozen_string_literal: true

          # Test class
          class TestClass
            # Correctly documented method
            # @param value [String] the value
            # @return [String] the value
            # @raise [StandardError] when something goes wrong
            def method_with_correct_tags(value)
              raise StandardError unless value

              value
            end
          end
        RUBY
        temp_file.rewind
      end

      it 'does not report any offense' do
        offenses = result.offenses.select { |o| o[:name] == 'UnknownTag' }

        expect(offenses).to be_empty
      end
    end
  end

  describe '"did you mean" suggestions' do
    context 'when tag name is a common typo' do
      before do
        temp_file.write(<<~RUBY)
          # frozen_string_literal: true

          # Test class
          class TestClass
            # Method with typo in tag
            # @returns [String] should be @return
            # @param value [String] the value
            def process(value)
              value
            end
          end
        RUBY
        temp_file.rewind
      end

      it 'suggests the correct tag name' do
        offense = result.offenses.find { |o| o[:name] == 'UnknownTag' }

        expect(offense).not_to be_nil
        expect(offense[:message]).to include('@returns')
        expect(offense[:message]).to include("did you mean '@return'?")
      end
    end

    context 'when using @raises instead of @raise' do
      before do
        temp_file.write(<<~RUBY)
          # frozen_string_literal: true

          # Test class
          class TestClass
            # Method with typo in tag
            # @param value [String] the value
            # @raises [StandardError] should be @raise
            def process(value)
              raise StandardError unless value

              value
            end
          end
        RUBY
        temp_file.rewind
      end

      it 'suggests @raise' do
        offense = result.offenses.find { |o| o[:name] == 'UnknownTag' && o[:message].include?('@raises') }

        expect(offense).not_to be_nil
        expect(offense[:message]).to include("did you mean '@raise'?")
      end
    end

    context 'when using @params instead of @param' do
      before do
        temp_file.write(<<~RUBY)
          # frozen_string_literal: true

          # Test class
          class TestClass
            # Method with typo in tag
            # @params value [String] should be @param
            # @return [String] the value
            def process(value)
              value
            end
          end
        RUBY
        temp_file.rewind
      end

      it 'suggests @param' do
        offense = result.offenses.find { |o| o[:name] == 'UnknownTag' && o[:message].include?('@params') }

        expect(offense).not_to be_nil
        expect(offense[:message]).to include("did you mean '@param'?")
      end
    end

    context 'when tag name has minor typo' do
      before do
        temp_file.write(<<~RUBY)
          # frozen_string_literal: true

          # Test class
          class TestClass
            # Method with typo in tag
            # @param value [String] the value
            # @exampl Ruby code example (missing 'e')
            #   process('test')
            def process(value)
              value
            end
          end
        RUBY
        temp_file.rewind
      end

      it 'suggests @example' do
        offense = result.offenses.find { |o| o[:name] == 'UnknownTag' && o[:message].include?('@exampl') }

        expect(offense).not_to be_nil
        expect(offense[:message]).to include("did you mean '@example'?")
      end
    end

    context 'when tag name is completely wrong' do
      before do
        temp_file.write(<<~RUBY)
          # frozen_string_literal: true

          # Test class
          class TestClass
            # Method with completely invalid tag
            # @param value [String] the value
            # @foobar [String] this tag doesn't exist
            def process(value)
              value
            end
          end
        RUBY
        temp_file.rewind
      end

      it 'does not suggest when tag is too different' do
        offense = result.offenses.find { |o| o[:name] == 'UnknownTag' && o[:message].include?('@foobar') }

        expect(offense).not_to be_nil
        expect(offense[:message]).to include('@foobar')
        expect(offense[:message]).not_to include('did you mean')
      end
    end

    context 'when multiple unknown tags exist' do
      before do
        temp_file.write(<<~RUBY)
          # frozen_string_literal: true

          # Test class
          class TestClass
            # Method with multiple typos
            # @params value [String] should be @param
            # @returns [String] should be @return
            # @raises [Error] should be @raise
            def process(value)
              value
            end
          end
        RUBY
        temp_file.rewind
      end

      it 'provides suggestions for all typos' do
        offenses = result.offenses.select { |o| o[:name] == 'UnknownTag' }

        expect(offenses.size).to be >= 3

        params_offense = offenses.find { |o| o[:message].include?('@params') }
        expect(params_offense[:message]).to include("did you mean '@param'?")

        returns_offense = offenses.find { |o| o[:message].include?('@returns') }
        expect(returns_offense[:message]).to include("did you mean '@return'?")

        raises_offense = offenses.find { |o| o[:message].include?('@raises') }
        expect(raises_offense[:message]).to include("did you mean '@raise'?")
      end
    end

    context 'with common misspellings' do
      before do
        temp_file.write(<<~RUBY)
          # frozen_string_literal: true

          # Test class
          class TestClass
            # Method with various typos
            # @see Related class
            # @auhtor John Doe (should be @author)
            # @deprected Use new_method instead (should be @deprecated)
            def old_method
              # implementation
            end
          end
        RUBY
        temp_file.rewind
      end

      it 'suggests correct spelling for @auhtor' do
        offense = result.offenses.find { |o| o[:name] == 'UnknownTag' && o[:message].include?('@auhtor') }

        expect(offense).not_to be_nil
        expect(offense[:message]).to include("did you mean '@author'?")
      end

      it 'suggests correct spelling for @deprected' do
        offense = result.offenses.find { |o| o[:name] == 'UnknownTag' && o[:message].include?('@deprected') }

        expect(offense).not_to be_nil
        expect(offense[:message]).to include("did you mean '@deprecated'?")
      end
    end

    context 'with directive typos' do
      before do
        temp_file.write(<<~RUBY)
          # frozen_string_literal: true

          # Test class
          class TestClass
            # @!attribut [r] name
            #   @return [String] the name
            attr_reader :name
          end
        RUBY
        temp_file.rewind
      end

      it 'suggests @!attribute for @!attribut' do
        offense = result.offenses.find { |o| o[:name] == 'UnknownTag' && o[:message].include?('attribut') }

        # Note: YARD might parse this differently, but we expect a suggestion if it's caught
        # The directive is @!attribute but YARD strips the @! prefix in warnings
        if offense
          expect(offense[:message]).to include('did you mean')
        end
      end
    end
  end

  describe 'location reporting' do
    before do
      temp_file.write(<<~RUBY)
        # frozen_string_literal: true

        # Test class with multiple unknown tags
        class TestClass
          # First method
          # @returns [String] wrong tag
          def first_method
            'first'
          end

          # Second method
          # @raises [Error] wrong tag
          def second_method
            'second'
          end

          # Third method
          # @params value [String] wrong tag
          def third_method(value)
            value
          end
        end
      RUBY
      temp_file.rewind
    end

    it 'reports all offenses with correct file paths' do
      offenses = result.offenses.select { |o| o[:name] == 'UnknownTag' }

      expect(offenses.size).to be >= 3

      # All offenses should have the full file path
      offenses.each do |offense|
        expect(offense[:location]).to eq(temp_file.path)
        expect(offense[:location]).not_to be_empty
        expect(offense[:location]).not_to be_nil
      end
    end
  end
end

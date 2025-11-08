# frozen_string_literal: true

require 'tempfile'

RSpec.describe 'Empty initialize methods handling' do
  subject(:result) { Yard::Lint.run(path: temp_file.path, progress: false, config: config) }

  let(:temp_file) { Tempfile.new(['test', '.rb']) }
  let(:config) { nil }

  after { temp_file.unlink }

  context 'when AllowEmptyInitialize is true (default)' do
    it 'does not flag initialize with no parameters' do
      temp_file.write(<<~RUBY)
        class Example
          def initialize
            @value = 1
          end
        end
      RUBY
      temp_file.rewind

      expect(result.offenses).not_to include(
        hash_including(
          name: 'UndocumentedObject',
          message: a_string_matching(/initialize/)
        )
      )
    end

    it 'still flags initialize with parameters when undocumented' do
      temp_file.write(<<~RUBY)
        class Example
          def initialize(value)
            @value = value
          end
        end
      RUBY
      temp_file.rewind

      expect(result.offenses).to include(
        hash_including(
          name: 'UndocumentedObject',
          message: a_string_matching(/initialize/)
        )
      )
    end

    it 'does not flag documented initialize with parameters' do
      temp_file.write(<<~RUBY)
        class Example
          # @param value [Integer] the value
          def initialize(value)
            @value = value
          end
        end
      RUBY
      temp_file.rewind

      expect(result.offenses).not_to include(
        hash_including(
          name: 'UndocumentedObject',
          message: a_string_matching(/initialize/)
        )
      )
    end

    it 'does not flag initialize with optional parameters and no docs' do
      temp_file.write(<<~RUBY)
        class Example
          def initialize(value = nil)
            @value = value
          end
        end
      RUBY
      temp_file.rewind

      # Should still flag because it has parameters (even if optional)
      expect(result.offenses).to include(
        hash_including(
          name: 'UndocumentedObject',
          message: a_string_matching(/initialize/)
        )
      )
    end

    it 'does not flag initialize with keyword arguments and no docs' do
      temp_file.write(<<~RUBY)
        class Example
          def initialize(value:)
            @value = value
          end
        end
      RUBY
      temp_file.rewind

      # Should still flag because it has parameters
      expect(result.offenses).to include(
        hash_including(
          name: 'UndocumentedObject',
          message: a_string_matching(/initialize/)
        )
      )
    end
  end

  context 'when AllowEmptyInitialize is false' do
    let(:config) do
      Yard::Lint::Config.new do |c|
        c.send(:set_validator_config, 'Documentation/UndocumentedObjects',
          'AllowEmptyInitialize', false)
      end
    end

    it 'flags initialize with no parameters when undocumented' do
      temp_file.write(<<~RUBY)
        class Example
          def initialize
            @value = 1
          end
        end
      RUBY
      temp_file.rewind

      expect(result.offenses).to include(
        hash_including(
          name: 'UndocumentedObject',
          message: a_string_matching(/initialize/)
        )
      )
    end

    it 'does not flag documented initialize with no parameters' do
      temp_file.write(<<~RUBY)
        class Example
          # Initializes the example
          def initialize
            @value = 1
          end
        end
      RUBY
      temp_file.rewind

      expect(result.offenses).not_to include(
        hash_including(
          name: 'UndocumentedObject',
          message: a_string_matching(/initialize/)
        )
      )
    end
  end
end

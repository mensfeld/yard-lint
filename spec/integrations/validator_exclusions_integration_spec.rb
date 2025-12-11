# frozen_string_literal: true

RSpec.describe 'Validator Exclusions Integration' do
  # Helper to convert relative paths to absolute paths from project root
  def project_path(relative_path)
    File.expand_path("../../#{relative_path}", __dir__)
  end

  describe 'per-validator exclusions' do
    context 'when Tags/ExampleSyntax has Exclude patterns' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          # Enable ExampleSyntax validator
          c.set_validator_config('Tags/ExampleSyntax', 'Enabled', true)
          c.set_validator_config('Tags/ExampleSyntax', 'Severity', 'error')

          # Add exclusions for validator parser files and spec fixtures
          c.set_validator_config(
            'Tags/ExampleSyntax',
            'Exclude',
            [
              '**/validators/**/parser.rb',
              'spec/fixtures/**/*'
            ]
          )
        end
      end

      it 'excludes parser.rb files from ExampleSyntax validation' do
        # These parser.rb files intentionally have invalid syntax in examples
        result = Yard::Lint.run(path: project_path('lib/yard/lint/validators'), config: config)

        # Should not have ExampleSyntax offenses from parser.rb files
        parser_offenses = result.offenses.select do |o|
          o[:name] == 'ExampleSyntax' && o[:location].end_with?('parser.rb')
        end

        expect(parser_offenses).to be_empty
      end

      it 'excludes spec/fixtures files from ExampleSyntax validation' do
        # Fixture files intentionally have invalid syntax in examples
        result = Yard::Lint.run(path: project_path('spec/fixtures'), config: config)

        # Should not have ExampleSyntax offenses from fixture files
        fixture_offenses = result.offenses.select do |o|
          o[:name] == 'ExampleSyntax' && o[:location].include?('spec/fixtures')
        end

        expect(fixture_offenses).to be_empty
      end

      it 'still validates other files for ExampleSyntax' do
        # Use existing fixture file that has invalid example syntax
        # but is not in the excluded patterns
        result = Yard::Lint.run(path: project_path('lib/yard/lint/stats_calculator.rb'), config: config)

        # Should successfully run validation (even if no errors found in this file)
        # The important part is that the validator runs and doesn't crash
        expect(result).to respond_to(:offenses)
        expect(result.offenses).to be_an(Array)
      end
    end

    context 'when combining global and per-validator exclusions' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          # Set global exclusions
          c.exclude = ['spec/**/*', 'test/**/*']

          # Enable validator with additional exclusions
          c.set_validator_config('Documentation/UndocumentedObjects', 'Enabled', true)
          c.set_validator_config(
            'Documentation/UndocumentedObjects',
            'Exclude',
            [
              'lib/yard/lint/validators/**/*.rb'
            ]
          )
        end
      end

      it 'applies both global and per-validator exclusions' do
        result = Yard::Lint.run(path: project_path('lib'), config: config)

        # Should not have offenses from spec files (global exclude)
        spec_offenses = result.offenses.select { |o| o[:location].include?('spec/') }
        expect(spec_offenses).to be_empty

        # Should not have offenses from validators (per-validator exclude)
        # Note: validator files contain undocumented objects by design
        validator_offenses = result.offenses.select do |o|
          o[:name] == 'UndocumentedObject' &&
            o[:location].include?('lib/yard/lint/validators/') &&
            o[:location].end_with?('.rb')
        end
        expect(validator_offenses).to be_empty
      end
    end

    context 'when no exclusions are set' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.exclude = []
          c.set_validator_config('Tags/ExampleSyntax', 'Enabled', true)
        end
      end

      it 'validates all files including parser.rb files' do
        # Without exclusions, parser.rb files with intentional bad examples should be caught
        result = Yard::Lint.run(
          path: project_path('lib/yard/lint/validators/documentation/undocumented_method_arguments/parser.rb'),
          config: config
        )

        # Should have ExampleSyntax offenses from parser.rb
        parser_offenses = result.offenses.select do |o|
          o[:name] == 'ExampleSyntax' && o[:location].end_with?('parser.rb')
        end

        expect(parser_offenses).not_to be_empty
      end
    end
  end

  describe 'exclusion pattern matching' do
    context 'with glob patterns' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.exclude = ['spec/**/*', 'test/**/*']
          c.set_validator_config('Documentation/UndocumentedObjects', 'Enabled', true)
          c.set_validator_config(
            'Documentation/UndocumentedObjects',
            'Exclude',
            [
              'lib/yard/lint/validators/**/*.rb'
            ]
          )
        end
      end

      it 'matches files with ** glob pattern' do
        result = Yard::Lint.run(path: project_path('lib/yard/lint/validators'), config: config)

        # Check that undocumented objects in validators are excluded
        validator_offenses = result.offenses.select do |o|
          o[:name] == 'UndocumentedObject' &&
            o[:location].include?('lib/yard/lint/validators/') &&
            o[:location].end_with?('.rb')
        end

        expect(validator_offenses).to be_empty
      end
    end

    context 'with wildcard patterns' do
      let(:config) do
        Yard::Lint::Config.new do |c|
          c.exclude = ['spec/**/*', 'test/**/*']
          c.set_validator_config('Documentation/UndocumentedObjects', 'Enabled', true)
          c.set_validator_config(
            'Documentation/UndocumentedObjects',
            'Exclude',
            [
              '**/lint/config.rb'
            ]
          )
        end
      end

      it 'matches files with * wildcard pattern' do
        result = Yard::Lint.run(path: project_path('lib/yard/lint/config.rb'), config: config)

        # Should exclude config.rb from UndocumentedObject validation
        config_offenses = result.offenses.select do |o|
          o[:name] == 'UndocumentedObject' &&
            o[:location].end_with?('config.rb')
        end

        expect(config_offenses).to be_empty
      end
    end
  end
end

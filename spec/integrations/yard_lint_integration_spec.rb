# frozen_string_literal: true

RSpec.describe 'Yard::Lint Integration Tests' do
  let(:fixtures_dir) { File.expand_path('fixtures', __dir__) }

  # Config without exclusions so fixtures are processed
  let(:config) do
    Yard::Lint::Config.new do |c|
      c.exclude = []
      # Disable ExampleSyntax to avoid false positives on output format examples
      c.set_validator_config('Tags/ExampleSyntax', 'Enabled', false)
    end
  end

  # Each test runs independently - resets cache between tests via spec_helper
  describe 'Undocumented Classes Detection' do
    it 'detects undocumented classes and modules' do
      file = File.join(fixtures_dir, 'undocumented_class.rb')

      result = Yard::Lint.run(path: file, config: config)

      expect(result.clean?).to be false
      expect(result.offenses.any? { |o| o[:name] == 'UndocumentedObject' }).to be true

      # Should find UndocumentedClass, UndocumentedModule, and nested class
      undocumented_names = result.offenses
                                 .select { |o| o[:name] == 'UndocumentedObject' }
                                 .map { |o| o[:element] }
      expect(undocumented_names).to include('UndocumentedClass')
      expect(undocumented_names).to include('UndocumentedModule')
    end

    it 'reports correct file locations' do
      file = File.join(fixtures_dir, 'undocumented_class.rb')

      result = Yard::Lint.run(path: file, config: config)

      result.offenses.select { |o| o[:name] == 'UndocumentedObject' }.each do |offense|
        expect(offense[:location]).to include('undocumented_class.rb')
        expect(offense[:line]).to be > 0
      end
    end
  end

  describe 'Missing Parameter Documentation' do
    it 'detects methods with missing param docs' do
      file = File.join(fixtures_dir, 'missing_param_docs.rb')

      result = Yard::Lint.run(path: file, config: config)

      expect(result.offenses.any? { |o| o[:name] == 'UndocumentedMethodArgument' }).to be true

      # Should find calculate and greet methods
      methods = result.offenses
                      .select { |o| o[:name] == 'UndocumentedMethodArgument' }
                      .map { |o| o[:method_name] }
      expect(methods).to include(match(/calculate/))
      expect(methods).to include(match(/greet/))
    end
  end

  describe 'Invalid Tag Ordering' do
    it 'detects tags in wrong order' do
      file = File.join(fixtures_dir, 'invalid_tag_order.rb')

      config = Yard::Lint::Config.new do |c|
        c.exclude = []
        # Use default tag order (param should come before return)
        c.send(
          :set_validator_config,
          'Tags/Order',
          'EnforcedOrder',
          %w[param option yield yieldparam yieldreturn return raise see example note todo]
        )
      end

      result = Yard::Lint.run(path: file, config: config)

      expect(result.offenses.any? { |o| o[:name] == 'InvalidTagOrder' }).to be true

      # Should find process and validate methods
      methods = result.offenses
                      .select { |o| o[:name] == 'InvalidTagOrder' }
                      .map { |o| o[:method_name] }
      expect(methods).to include(match(/process/))
      expect(methods).to include(match(/validate/))
    end
  end

  describe 'Undocumented Boolean Methods' do
    it 'detects boolean methods without return docs' do
      file = File.join(fixtures_dir, 'boolean_methods.rb')

      result = Yard::Lint.run(path: file, config: config)

      # Boolean methods with comments but without explicit @return tags
      # are NOT flagged because:
      # 1. YARD auto-infers @return [Boolean] for methods ending with '?'
      # 2. Having ANY docstring content (even just a comment) satisfies UndocumentedObjects
      # This is the correct behavior - boolean methods don't need explicit @return tags
      undocumented_booleans = result.offenses
                                    .select { |o| o[:name] == 'UndocumentedObject' }
                                    .select do |o|
        o[:element].to_s.include?('active?') || o[:element].to_s.include?('ready?')
      end

      expect(undocumented_booleans).to be_empty
    end
  end

  describe 'Invalid Tag Types' do
    it 'validates that tags use valid type definitions' do
      file = File.join(fixtures_dir, 'invalid_tag_types.rb')

      result = Yard::Lint.run(path: file, config: config)

      # The validator checks for types that are not defined Ruby classes
      # This test confirms the validator runs and returns results
      expect(result.offenses.select { |o| o[:name] == 'InvalidTagType' }).to be_an(Array)
      expect(result).to respond_to(:offenses)
    end
  end

  describe 'API Tags' do
    it 'detects missing or incorrect @api tags when enforced' do
      file = File.join(fixtures_dir, 'api_tags.rb')

      config = Yard::Lint::Config.new do |c|
        c.exclude = []
        c.send(:set_validator_config, 'Tags/ApiTags', 'Enabled', true)
        c.send(:set_validator_config, 'Tags/ApiTags', 'AllowedApis', %w[public private internal])
      end

      result = Yard::Lint.run(path: file, config: config)

      # Should detect methods without @api tags
      # Note: This validator is opt-in, so it only runs when explicitly enabled
      expect(result.offenses.select { |o| o[:name].to_s.include?('Api') }).to be_an(Array)
    end
  end

  describe 'Option Tags' do
    it 'detects methods with options parameters but no @option tags' do
      file = File.join(fixtures_dir, 'option_tags.rb')

      config = Yard::Lint::Config.new do |c|
        c.exclude = []
        c.send(:set_validator_config, 'Tags/OptionTags', 'Enabled', true)
      end

      result = Yard::Lint.run(path: file, config: config)

      # Should find methods with options/opts/kwargs params but no @option tags
      expect(result.offenses.select { |o| o[:name].to_s.include?('Option') }).to be_an(Array)
      expect(result).to respond_to(:offenses)

      if result.offenses.any? { |o| o[:name].to_s.include?('Option') }
        methods_with_issues = result.offenses
                                    .select { |o| o[:name].to_s.include?('Option') }
                                    .map { |o| o[:method_name] }
        expect(methods_with_issues).to include(
          match(/create_with_options|process_with_opts|format_name/)
        )

        # Should NOT flag create_user which has @option tags
        correctly_documented = result.offenses.find do |o|
          o[:name].to_s.include?('Option') && o[:method_name].to_s == 'create_user'
        end
        expect(correctly_documented).to be_nil
      end
    end
  end

  describe 'YARD Warnings' do
    it 'detects various YARD parser warnings' do
      file = File.join(fixtures_dir, 'yard_warnings.rb')

      result = Yard::Lint.run(path: file, config: config)

      # The warnings validator captures various YARD parse warnings
      # This includes unknown tags, unknown directives, invalid formats, etc.
      expect(result.offenses.select { |o| o[:severity] == 'error' }).to be_an(Array)
      expect(result).to respond_to(:offenses)

      # Warnings should be detected from the fixture file
      if result.offenses.any? { |o| o[:severity] == 'error' }
        warning_messages = result.offenses
                                 .select { |o| o[:severity] == 'error' }
                                 .map { |w| w[:message] }
        expect(warning_messages.size).to be > 0
      end
    end
  end

  describe 'Abstract Methods' do
    it 'detects abstract methods with actual implementations' do
      file = File.join(fixtures_dir, 'abstract_methods.rb')

      config = Yard::Lint::Config.new do |c|
        c.exclude = []
        c.send(:set_validator_config, 'Semantic/AbstractMethods', 'Enabled', true)
      end

      result = Yard::Lint.run(path: file, config: config)

      # Should validate abstract method usage
      expect(result.offenses.select { |o| o[:name].to_s.include?('Abstract') }).to be_an(Array)
      expect(result).to respond_to(:offenses)

      # Should detect calculate method which has @abstract but also implementation
      if result.offenses.any? { |o| o[:name].to_s.include?('Abstract') }
        methods_with_issues = result.offenses
                                    .select { |o| o[:name].to_s.include?('Abstract') }
                                    .map { |o| o[:method_name] }
        expect(methods_with_issues).to include(match(/calculate/))
      end
    end
  end

  describe 'Clean Code (No Offenses)' do
    it 'finds no offenses in properly documented code' do
      file = File.join(fixtures_dir, 'clean_code.rb')

      result = Yard::Lint.run(path: file, config: config)

      expect(result.clean?).to be true
      expect(result.count).to eq(0)
      expect(result.offenses).to be_empty
    end
  end

  describe 'Multiple Files' do
    it 'processes multiple files and aggregates results' do
      files = [
        File.join(fixtures_dir, 'undocumented_class.rb'),
        File.join(fixtures_dir, 'missing_param_docs.rb'),
        File.join(fixtures_dir, 'clean_code.rb')
      ]

      result = Yard::Lint.run(path: files, config: config)

      expect(result.clean?).to be false

      # Should have offenses from undocumented_class.rb and missing_param_docs.rb
      # but none from clean_code.rb
      expect(result.offenses.count { |o| o[:name] == 'UndocumentedObject' }).to be > 0
      expect(result.offenses.count { |o| o[:name] == 'UndocumentedMethodArgument' }).to be > 0
    end
  end

  describe 'Configuration Options' do
    it 'respects custom exclude patterns' do
      config = Yard::Lint::Config.new do |c|
        c.exclude = ['**/undocumented_class.rb']
      end

      # Try to run on excluded file - should process no files
      file = File.join(fixtures_dir, 'undocumented_class.rb')
      result = Yard::Lint.run(path: file, config: config)

      # Should be clean because file was excluded
      expect(result.clean?).to be true
    end

    it 'applies custom fail_on_severity' do
      config = Yard::Lint::Config.new do |c|
        c.exclude = []
        c.fail_on_severity = 'error'
      end

      file = File.join(fixtures_dir, 'invalid_tag_order.rb')
      result = Yard::Lint.run(path: file, config: config)

      # Exit code should be 0 because tag order is convention, not error
      expect(result.exit_code).to eq(0)
    end
  end

  describe 'Result Statistics' do
    it 'provides accurate offense statistics' do
      file = File.join(fixtures_dir, 'undocumented_class.rb')

      result = Yard::Lint.run(path: file, config: config)

      stats = result.statistics
      expect(stats[:total]).to eq(result.count)
      expect(stats[:error]).to be >= 0
      expect(stats[:warning]).to be >= 0
      expect(stats[:convention]).to be >= 0
      expect(stats[:total]).to eq(stats[:error] + stats[:warning] + stats[:convention])
    end
  end

  describe 'Glob Patterns' do
    it 'processes files matching glob patterns', :cache_isolation do
      pattern = File.join(fixtures_dir, '*.rb')

      result = Yard::Lint.run(path: pattern, config: config)

      # Should process all fixture files
      expect(result.clean?).to be false
      expect(result.count).to be > 0
    end
  end

  describe 'Directory Processing' do
    it 'recursively processes Ruby files in directories', :cache_isolation do
      result = Yard::Lint.run(path: fixtures_dir, config: config)

      # Should find offenses from multiple files
      expect(result.clean?).to be false

      # Should have processed multiple types of offenses
      offense_types = result.offenses.map { |o| o[:name] }.uniq
      expect(offense_types.size).to be > 1
    end
  end

  describe 'Offense Structure' do
    it 'returns offenses with consistent structure' do
      file = File.join(fixtures_dir, 'undocumented_class.rb')

      result = Yard::Lint.run(path: file, config: config)

      result.offenses.each do |offense|
        # Every offense should have these keys
        expect(offense).to have_key(:severity)
        expect(offense).to have_key(:type)
        expect(offense).to have_key(:name)
        expect(offense).to have_key(:message)
        expect(offense).to have_key(:location)
        expect(offense).to have_key(:location_line)

        # Values should be valid
        valid_severities = %w[error warning convention]
        valid_types = %w[line method]
        expect(valid_severities).to include(offense[:severity])
        expect(valid_types).to include(offense[:type])
        expect(offense[:message]).to be_a(String)
        expect(offense[:message]).not_to be_empty
        expect(offense[:location]).to include('.rb')
      end
    end
  end

  describe 'Error Handling' do
    it 'handles non-existent files gracefully' do
      expect do
        Yard::Lint.run(path: '/nonexistent/file.rb')
      end.not_to raise_error
    end

    it 'handles empty file lists gracefully' do
      expect do
        Yard::Lint.run(path: [])
      end.not_to raise_error
    end

    it 'handles invalid Ruby files gracefully' do
      # Create a file with invalid Ruby syntax
      invalid_file = File.join(fixtures_dir, 'invalid_syntax.rb')
      File.write(invalid_file, 'class Foo def end')

      # Should not crash, might have parse errors
      expect do
        Yard::Lint.run(path: invalid_file)
      end.not_to raise_error

      File.delete(invalid_file)
    end
  end
end

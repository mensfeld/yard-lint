# frozen_string_literal: true

RSpec.describe Yard::Lint::ResultBuilder do
  let(:config) { Yard::Lint::Config.new }
  let(:builder) { described_class.new(config) }

  describe '#initialize' do
    it 'stores config' do
      expect(builder.config).to eq(config)
    end
  end

  describe '#build' do
    context 'with composite validator (UndocumentedObjects)' do
      let(:validator_name) { 'Documentation/UndocumentedObjects' }
      let(:raw_results) do
        {
          undocumented_objects: {
            stdout: "file.rb:10: MyClass\nfile.rb:20: MyModule",
            stderr: '',
            exit_code: 0
          },
          undocumented_boolean_methods: {
            stdout: 'file.rb:30: MyClass#valid?',
            stderr: '',
            exit_code: 0
          }
        }
      end

      it 'combines results from parent and child validators' do
        result = builder.build(validator_name, raw_results)

        expect(result).to be_a(Yard::Lint::Results::Base)
        # Should combine offenses from both validators
        expect(result.offenses.size).to eq(3)
      end

      it 'returns nil when all validators have no output' do
        empty_results = {
          undocumented_objects: { stdout: '', stderr: '', exit_code: 0 },
          undocumented_boolean_methods: { stdout: '', stderr: '', exit_code: 0 }
        }
        result = builder.build(validator_name, empty_results)

        expect(result).to be_nil
      end

      it 'includes partial results when only one child has output' do
        partial_results = {
          undocumented_objects: { stdout: '', stderr: '', exit_code: 0 },
          undocumented_boolean_methods: {
            stdout: 'file.rb:30: MyClass#valid?',
            stderr: '',
            exit_code: 0
          }
        }
        result = builder.build(validator_name, partial_results)

        expect(result).not_to be_nil
        expect(result.offenses.size).to eq(1)
      end
    end

    context 'with composite child validator (UndocumentedBooleanMethods)' do
      let(:validator_name) { 'Documentation/UndocumentedBooleanMethods' }
      let(:raw_results) do
        {
          undocumented_boolean_methods: {
            stdout: 'file.rb:30: MyClass#valid?',
            stderr: '',
            exit_code: 0
          }
        }
      end

      it 'returns nil (skipped because handled by parent composite)' do
        result = builder.build(validator_name, raw_results)

        expect(result).to be_nil
      end
    end

    context 'with multi-parser validator (Warnings/Stats)' do
      let(:validator_name) { 'Warnings/Stats' }
      let(:raw_results) do
        {
          stats: {
            stdout: '[warn]: Unknown tag @example1 in file `file.rb` near line 5\n' \
                    '[warn]: @param tag has unknown parameter name: wrong_name for method ' \
                    "'Foo#bar' in file `file.rb` near line 10\n",
            stderr: '',
            exit_code: 0
          }
        }
      end

      it 'discovers and uses multiple parsers' do
        result = builder.build(validator_name, raw_results)

        expect(result).to be_a(Yard::Lint::Results::Base)
        # Should have parsed offenses from multiple parser classes
        expect(result.offenses.size).to be >= 2
      end

      it 'returns nil when no warnings' do
        empty_results = { stats: { stdout: '', stderr: '', exit_code: 0 } }
        result = builder.build(validator_name, empty_results)

        expect(result).to be_nil
      end
    end

    context 'with standard validator returning nil' do
      it 'returns nil when no output' do
        result = builder.build('Tags/Order', {})

        expect(result).to be_nil
      end

      it 'returns nil when output is empty' do
        empty_results = { tags_order: { stdout: '', stderr: '', exit_code: 0 } }
        result = builder.build('Tags/Order', empty_results)

        expect(result).to be_nil
      end
    end
  end

  describe 'parser discovery' do
    it 'discovers multiple parsers for Stats validator' do
      result = builder.build(
        'Warnings/Stats',
        {
          stats: {
            stdout: "[warn]: Unknown tag @test in file `file.rb` near line 5\n" \
                    "[warn]: Unknown directive @!test in file `file.rb` near line 10\n",
            stderr: '',
            exit_code: 0
          }
        }
      )

      # Multiple parsers discovered and used
      expect(result).to be_a(Yard::Lint::Results::Base)
    end
  end

  describe 'composite detection' do
    it 'skips composite children automatically' do
      # UndocumentedBooleanMethods is a child of UndocumentedObjects composite
      result = builder.build(
        'Documentation/UndocumentedBooleanMethods',
        {
          undocumented_boolean_methods: {
            stdout: 'file.rb:30: MyClass#valid?',
            stderr: '',
            exit_code: 0
          }
        }
      )

      expect(result).to be_nil
    end

    it 'processes parent composites' do
      # UndocumentedObjects is the parent composite
      result = builder.build(
        'Documentation/UndocumentedObjects',
        {
          undocumented_objects: {
            stdout: 'file.rb:10: MyClass',
            stderr: '',
            exit_code: 0
          }
        }
      )

      expect(result).not_to be_nil
    end
  end
end

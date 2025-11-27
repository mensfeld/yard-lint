# frozen_string_literal: true

RSpec.describe Yard::Lint::Executor::QueryExecutor do
  let(:registry) { instance_double(Yard::Lint::Executor::InProcessRegistry) }
  let(:executor) { described_class.new(registry) }

  describe '#initialize' do
    it 'stores the registry' do
      expect(executor.instance_variable_get(:@registry)).to eq(registry)
    end
  end

  describe '#execute' do
    let(:config) { Yard::Lint::Config.new }
    let(:validator_class) do
      Class.new(Yard::Lint::Validators::Base) do
        def self.validator_name
          'Test/Validator'
        end

        def self.in_process_visibility
          :public
        end

        def in_process_query(object, collector)
          collector.puts("test:#{object.path}:1")
        end
      end
    end
    let(:validator) { validator_class.new(config, []) }

    let(:mock_object) do
      instance_double(
        YARD::CodeObjects::MethodObject,
        file: 'lib/test.rb',
        line: 10,
        path: 'TestClass#method',
        visibility: :public
      )
    end

    before do
      allow(registry).to receive(:objects_for_validator).and_return([mock_object])
      allow(config).to receive(:validator_exclude).with('Test/Validator').and_return([])
    end

    it 'returns a result hash with stdout, stderr, and exit_code' do
      result = executor.execute(validator)

      expect(result).to include(:stdout, :stderr, :exit_code)
      expect(result[:stderr]).to eq('')
      expect(result[:exit_code]).to eq(0)
    end

    it 'calls registry.objects_for_validator with correct visibility' do
      executor.execute(validator)

      expect(registry).to have_received(:objects_for_validator).with(
        visibility: :public,
        file_excludes: [],
        file_selection: nil
      )
    end

    it 'passes file_selection to registry when provided' do
      executor.execute(validator, file_selection: ['lib/foo.rb'])

      expect(registry).to have_received(:objects_for_validator).with(
        visibility: :public,
        file_excludes: [],
        file_selection: ['lib/foo.rb']
      )
    end

    it 'skips objects without file info' do
      object_without_file = instance_double(
        YARD::CodeObjects::MethodObject,
        file: nil,
        line: 10,
        path: 'NoFile#method'
      )
      allow(registry).to receive(:objects_for_validator).and_return([object_without_file])

      result = executor.execute(validator)

      expect(result[:stdout]).to eq('')
    end

    it 'skips objects without line info' do
      object_without_line = instance_double(
        YARD::CodeObjects::MethodObject,
        file: 'lib/test.rb',
        line: nil,
        path: 'NoLine#method'
      )
      allow(registry).to receive(:objects_for_validator).and_return([object_without_line])

      result = executor.execute(validator)

      expect(result[:stdout]).to eq('')
    end

    it 'processes objects with both file and line info' do
      result = executor.execute(validator)

      expect(result[:stdout]).to include('test:TestClass#method:1')
    end

    context 'with file excludes from config' do
      before do
        allow(config).to receive(:validator_exclude)
          .with('Test/Validator')
          .and_return(['spec/**/*'])
      end

      it 'passes excludes to registry' do
        executor.execute(validator)

        expect(registry).to have_received(:objects_for_validator).with(
          visibility: :public,
          file_excludes: ['spec/**/*'],
          file_selection: nil
        )
      end
    end
  end

  describe '#determine_visibility (via execute)' do
    let(:mock_object) do
      instance_double(
        YARD::CodeObjects::MethodObject,
        file: 'lib/test.rb',
        line: 10,
        path: 'TestClass#method',
        visibility: :public
      )
    end

    before do
      allow(registry).to receive(:objects_for_validator).and_return([mock_object])
    end

    context 'when validator has no config' do
      let(:validator_class) do
        Class.new(Yard::Lint::Validators::Base) do
          def self.validator_name
            'Tags/Order'
          end

          def self.in_process_visibility
            :all
          end

          def in_process_query(_object, _collector); end
        end
      end

      it 'uses validator in_process_visibility' do
        validator = validator_class.new(nil, [])
        executor.execute(validator)

        expect(registry).to have_received(:objects_for_validator).with(
          hash_including(visibility: :all)
        )
      end
    end

    context 'when config has --private in global YardOptions' do
      let(:config) do
        Yard::Lint::Config.new(
          {
            'AllValidators' => { 'YardOptions' => ['--private'] },
            'Tags/Order' => { 'Enabled' => true }
          }
        )
      end
      let(:validator_class) do
        Class.new(Yard::Lint::Validators::Base) do
          def self.validator_name
            'Tags/Order'
          end

          def self.in_process_visibility
            :public
          end

          def in_process_query(_object, _collector); end
        end
      end

      it 'uses :all visibility when inheriting --private' do
        validator = validator_class.new(config, [])
        executor.execute(validator)

        expect(registry).to have_received(:objects_for_validator).with(
          hash_including(visibility: :all)
        )
      end
    end

    context 'when config has --protected in global YardOptions' do
      let(:config) do
        Yard::Lint::Config.new(
          {
            'AllValidators' => { 'YardOptions' => ['--protected'] },
            'Tags/Order' => { 'Enabled' => true }
          }
        )
      end
      let(:validator_class) do
        Class.new(Yard::Lint::Validators::Base) do
          def self.validator_name
            'Tags/Order'
          end

          def self.in_process_visibility
            :public
          end

          def in_process_query(_object, _collector); end
        end
      end

      it 'uses :all visibility when inheriting --protected' do
        validator = validator_class.new(config, [])
        executor.execute(validator)

        expect(registry).to have_received(:objects_for_validator).with(
          hash_including(visibility: :all)
        )
      end
    end

    context 'when validator has explicit empty YardOptions' do
      let(:config) do
        Yard::Lint::Config.new(
          {
            'AllValidators' => { 'YardOptions' => ['--private'] },
            'Tags/Order' => { 'Enabled' => true, 'YardOptions' => [] }
          }
        )
      end
      let(:validator_class) do
        Class.new(Yard::Lint::Validators::Base) do
          def self.validator_name
            'Tags/Order'
          end

          def self.in_process_visibility
            :all
          end

          def in_process_query(_object, _collector); end
        end
      end

      it 'uses :public visibility overriding validator default' do
        validator = validator_class.new(config, [])
        executor.execute(validator)

        expect(registry).to have_received(:objects_for_validator).with(
          hash_including(visibility: :public)
        )
      end
    end

    context 'when validator has --private in its own YardOptions' do
      let(:config) do
        Yard::Lint::Config.new(
          {
            'AllValidators' => { 'YardOptions' => [] },
            'Tags/Order' => { 'Enabled' => true, 'YardOptions' => ['--private'] }
          }
        )
      end
      let(:validator_class) do
        Class.new(Yard::Lint::Validators::Base) do
          def self.validator_name
            'Tags/Order'
          end

          def self.in_process_visibility
            :public
          end

          def in_process_query(_object, _collector); end
        end
      end

      it 'uses :all visibility from validator-specific YardOptions' do
        validator = validator_class.new(config, [])
        executor.execute(validator)

        expect(registry).to have_received(:objects_for_validator).with(
          hash_including(visibility: :all)
        )
      end
    end

    context 'when validator has no YardOptions key and global is empty' do
      let(:config) do
        Yard::Lint::Config.new(
          {
            'AllValidators' => { 'YardOptions' => [] },
            'Tags/Order' => { 'Enabled' => true }
          }
        )
      end
      let(:validator_class) do
        Class.new(Yard::Lint::Validators::Base) do
          def self.validator_name
            'Tags/Order'
          end

          def self.in_process_visibility
            :all
          end

          def in_process_query(_object, _collector); end
        end
      end

      it 'falls back to validator in_process_visibility' do
        validator = validator_class.new(config, [])
        executor.execute(validator)

        expect(registry).to have_received(:objects_for_validator).with(
          hash_including(visibility: :all)
        )
      end
    end
  end

  describe 'error handling' do
    let(:config) { Yard::Lint::Config.new }
    let(:mock_object) do
      instance_double(
        YARD::CodeObjects::MethodObject,
        file: 'lib/test.rb',
        line: 10,
        path: 'TestClass#method',
        visibility: :public
      )
    end

    before do
      allow(registry).to receive(:objects_for_validator).and_return([mock_object])
    end

    context 'when validator raises NotImplementedError' do
      let(:validator_class) do
        Class.new(Yard::Lint::Validators::Base) do
          def self.validator_name
            'Test/Validator'
          end

          def self.in_process_visibility
            :public
          end

          def in_process_query(_object, _collector)
            raise NotImplementedError, 'not implemented'
          end
        end
      end

      it 're-raises the error' do
        validator = validator_class.new(config, [])
        allow(config).to receive(:validator_exclude).and_return([])

        expect { executor.execute(validator) }.to raise_error(NotImplementedError)
      end
    end

    context 'when validator raises NoMethodError' do
      let(:validator_class) do
        Class.new(Yard::Lint::Validators::Base) do
          def self.validator_name
            'Test/Validator'
          end

          def self.in_process_visibility
            :public
          end

          def in_process_query(_object, _collector)
            raise NoMethodError, 'undefined method'
          end
        end
      end

      it 're-raises the error' do
        validator = validator_class.new(config, [])
        allow(config).to receive(:validator_exclude).and_return([])

        expect { executor.execute(validator) }.to raise_error(NoMethodError)
      end
    end

    context 'when validator raises StandardError' do
      let(:validator_class) do
        Class.new(Yard::Lint::Validators::Base) do
          def self.validator_name
            'Test/Validator'
          end

          def self.in_process_visibility
            :public
          end

          def in_process_query(_object, _collector)
            raise StandardError, 'some error'
          end
        end
      end

      it 'catches the error and continues' do
        validator = validator_class.new(config, [])
        allow(config).to receive(:validator_exclude).and_return([])

        expect { executor.execute(validator) }.not_to raise_error
      end

      it 'returns empty result when error occurs' do
        validator = validator_class.new(config, [])
        allow(config).to receive(:validator_exclude).and_return([])

        result = executor.execute(validator)

        expect(result[:stdout]).to eq('')
        expect(result[:exit_code]).to eq(0)
      end
    end
  end
end

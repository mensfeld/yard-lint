# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::TagGroupSeparator::Validator do
  let(:config) { Yard::Lint::Config.new }
  let(:selection) { ['lib/example.rb'] }
  let(:validator) { described_class.new(config, selection) }

  describe '#initialize' do
    it 'inherits from Base validator' do
      expect(validator).to be_a(Yard::Lint::Validators::Base)
    end

    it 'stores config and selection' do
      expect(validator.config).to eq(config)
      expect(validator.selection).to eq(selection)
    end
  end

  describe '.in_process?' do
    it 'returns true for in-process execution' do
      expect(described_class.in_process?).to be true
    end
  end

  describe '#in_process_query' do
    let(:collector) { Yard::Lint::Executor::ResultCollector.new }

    context 'with properly separated tag groups' do
      let(:docstring) do
        <<~DOC
          Description of method.

          @param id [String] the ID
          @param name [String] the name

          @return [Object] the result
        DOC
      end

      it 'reports valid when tag groups are properly separated' do
        object = mock_yard_object(docstring: docstring)
        validator.in_process_query(object, collector)
        output = collector.to_stdout
        expect(output).to include('valid')
      end
    end

    context 'with missing separator between param and return' do
      let(:docstring) do
        <<~DOC
          Description of method.

          @param id [String] the ID
          @return [Object] the result
        DOC
      end

      it 'reports missing separator' do
        object = mock_yard_object(docstring: docstring)
        validator.in_process_query(object, collector)
        output = collector.to_stdout
        expect(output).to include('param->return')
      end
    end

    context 'with multiple missing separators' do
      let(:docstring) do
        <<~DOC
          @param id [String] the ID
          @return [Object] the result
          @raise [Error] when something fails
        DOC
      end

      it 'reports all missing separators' do
        object = mock_yard_object(docstring: docstring)
        validator.in_process_query(object, collector)
        output = collector.to_stdout
        expect(output).to include('param->return')
        expect(output).to include('return->error')
      end
    end

    context 'with same-group consecutive tags' do
      let(:docstring) do
        <<~DOC
          @param id [String] the ID
          @param name [String] the name
          @option opts [String] :foo the foo
        DOC
      end

      it 'reports valid for same-group tags without separator' do
        object = mock_yard_object(docstring: docstring)
        validator.in_process_query(object, collector)
        output = collector.to_stdout
        expect(output).to include('valid')
      end
    end

    context 'with empty docstring' do
      let(:docstring) { '' }

      it 'does not report any issues' do
        object = mock_yard_object(docstring: docstring)
        validator.in_process_query(object, collector)
        output = collector.to_stdout
        expect(output).to be_empty
      end
    end

    context 'with alias object' do
      let(:docstring) { '@param id [String]' }

      it 'skips alias objects' do
        object = mock_yard_object(docstring: docstring, is_alias: true)
        validator.in_process_query(object, collector)
        output = collector.to_stdout
        expect(output).to be_empty
      end
    end

    context 'with unknown tags' do
      let(:docstring) do
        <<~DOC
          @param id [String] the ID
          @custom_tag some value
        DOC
      end

      it 'treats unknown tags as their own group' do
        object = mock_yard_object(docstring: docstring)
        validator.in_process_query(object, collector)
        output = collector.to_stdout
        expect(output).to include('param->custom_tag')
      end
    end

    context 'with multiline tag content' do
      let(:docstring) do
        <<~DOC
          @param id [String] the ID
            with additional description
            spanning multiple lines
          @param name [String] the name
        DOC
      end

      it 'handles multiline tags correctly' do
        object = mock_yard_object(docstring: docstring)
        validator.in_process_query(object, collector)
        output = collector.to_stdout
        expect(output).to include('valid')
      end
    end
  end

  def mock_yard_object(docstring:, is_alias: false)
    object = instance_double(YARD::CodeObjects::MethodObject)
    docstring_obj = instance_double(YARD::Docstring)

    allow(object).to receive_messages(
      is_alias?: is_alias,
      docstring: docstring_obj,
      file: 'lib/example.rb',
      line: 10,
      title: 'Example#method'
    )
    allow(docstring_obj).to receive(:all).and_return(docstring)

    object
  end
end

# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::ExampleStyle::Validator do
  describe 'class configuration' do
    it 'enables in-process execution' do
      expect(described_class).to be_in_process
    end

    it 'uses all visibility' do
      expect(described_class.in_process_visibility).to eq(:all)
    end

    it 'inherits from base validator' do
      expect(described_class.superclass).to eq(Yard::Lint::Validators::Base)
    end
  end

  describe '#in_process_query' do
    let(:config) { Yard::Lint::Config.new }
    let(:validator) { described_class.new(config, []) }
    let(:collector) { double('collector', puts: nil) }

    context 'when object has no @example tags' do
      it 'does not output anything' do
        object = double('object', has_tag?: false)

        expect(collector).not_to receive(:puts)
        validator.in_process_query(object, collector)
      end
    end

    context 'when no linter is available' do
      it 'returns early without processing' do
        object = double('object', has_tag?: true, tags: [])

        allow(Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector).to receive(:detect).and_return(:none)

        expect(collector).not_to receive(:puts)
        validator.in_process_query(object, collector)
      end
    end

    context 'when linter is available' do
      let(:example) { double('example', text: 'user = User.new', name: 'Basic usage') }
      let(:object) do
        double(
          'object',
          has_tag?: true,
          tags: [example],
          file: 'lib/user.rb',
          line: 10,
          title: 'User#initialize'
        )
      end

      before do
        allow(Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector).to receive(:detect).and_return(:rubocop)
      end

      it 'processes examples and outputs offenses' do
        runner = double('runner')
        offenses = [
          {
            cop_name: 'Style/StringLiterals',
            message: 'Prefer single-quoted strings',
            line: 1,
            column: 10,
            severity: 'convention'
          }
        ]

        allow(Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner).to receive(:new).and_return(runner)
        allow(runner).to receive(:run).and_return(offenses)

        expect(collector).to receive(:puts).with('lib/user.rb:10: User#initialize')
        expect(collector).to receive(:puts).with('style_offense')
        expect(collector).to receive(:puts).with('Basic usage')
        expect(collector).to receive(:puts).with('Style/StringLiterals')
        expect(collector).to receive(:puts).with('Prefer single-quoted strings')

        validator.in_process_query(object, collector)
      end

      it 'uses default example name when name is nil' do
        unnamed_example = double('example', text: 'user = User.new', name: nil)
        object = double(
          'object',
          has_tag?: true,
          tags: [unnamed_example],
          file: 'lib/user.rb',
          line: 10,
          title: 'User#initialize'
        )

        runner = double('runner')
        allow(Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner).to receive(:new).and_return(runner)
        allow(runner).to receive(:run).with('user = User.new', 'Example 1', file_path: 'lib/user.rb').and_return([])

        validator.in_process_query(object, collector)
      end

      it 'skips examples with nil or empty code' do
        nil_example = double('example', text: nil, name: 'Nil example')
        empty_example = double('example', text: '', name: 'Empty example')
        object = double(
          'object',
          has_tag?: true,
          tags: [nil_example, empty_example],
          file: 'lib/user.rb',
          line: 10,
          title: 'User#initialize'
        )

        runner = double('runner')
        allow(Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner).to receive(:new).and_return(runner)

        expect(runner).not_to receive(:run)
        validator.in_process_query(object, collector)
      end

      it 'passes configuration to runner' do
        config_hash = {
          'Tags/ExampleStyle' => {
            'DisabledCops' => ['Style/FrozenStringLiteralComment'],
            'SkipPatterns' => ['/skip-lint/i']
          }
        }
        config = Yard::Lint::Config.new(config_hash)
        validator = described_class.new(config, [])

        runner = double('runner')
        expect(Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner).to receive(:new).with(
          hash_including(
            linter: :rubocop,
            disabled_cops: array_including('Style/FrozenStringLiteralComment')
          )
        ).and_return(runner)

        allow(runner).to receive(:run).and_return([])

        validator.in_process_query(object, collector)
      end
    end
  end
end

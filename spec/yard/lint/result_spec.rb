# frozen_string_literal: true

RSpec.describe Yard::Lint::Result do
  let(:empty_data) do
    {
      warnings: [],
      undocumented: [],
      undocumented_method_arguments: [],
      invalid_tags_types: [],
      invalid_tags_order: []
    }
  end

  describe "#initialize" do
    it 'initializes with empty arrays when data is empty' do
      result = described_class.new(empty_data)

      expect(result.warnings).to eq([])
      expect(result.undocumented).to eq([])
      expect(result.undocumented_method_arguments).to eq([])
      expect(result.invalid_tags_types).to eq([])
      expect(result.invalid_tags_order).to eq([])
    end
  end

  describe "#offenses" do
    it 'returns empty array when there are no offenses' do
      result = described_class.new(empty_data)

      expect(result.offenses).to eq([])
    end

    it 'formats warnings as error severity offenses' do
      data = empty_data.merge(
        warnings: [
          { name: 'UnknownTag', message: 'Unknown tag @foo', location: 'lib/test.rb', line: 10 }
        ]
      )

      result = described_class.new(data)
      offense = result.offenses.first

      expect(offense[:severity]).to eq('error')
      expect(offense[:type]).to eq('line')
      expect(offense[:name]).to eq('UnknownTag')
      expect(offense[:message]).to eq('Unknown tag @foo')
      expect(offense[:location]).to eq('lib/test.rb')
      expect(offense[:location_line]).to eq(10)
    end

    it 'formats undocumented objects as warning severity offenses' do
      data = empty_data.merge(
        undocumented: [
          { element: 'MyClass', location: 'lib/test.rb', line: 5 }
        ]
      )

      result = described_class.new(data)
      offense = result.offenses.first

      expect(offense[:severity]).to eq('warning')
      expect(offense[:name]).to eq('UndocumentedObject')
      expect(offense[:message]).to include('MyClass')
      expect(offense[:location]).to eq('lib/test.rb')
      expect(offense[:location_line]).to eq(5)
    end

    it 'formats invalid tags order as convention severity offenses' do
      data = empty_data.merge(
        invalid_tags_order: [
          { method_name: 'foo', order: 'param,return', location: 'lib/test.rb', line: 15 }
        ]
      )

      result = described_class.new(data)
      offense = result.offenses.first

      expect(offense[:severity]).to eq('convention')
      expect(offense[:name]).to eq('InvalidTagsOrder')
      expect(offense[:message]).to include('foo')
      expect(offense[:location]).to eq('lib/test.rb')
      expect(offense[:location_line]).to eq(15)
    end
  end

  describe "#count" do
    it 'returns 0 when there are no offenses' do
      result = described_class.new(empty_data)

      expect(result.count).to eq(0)
    end

    it 'returns total count of all offenses' do
      data = empty_data.merge(
        warnings: [{ name: 'Test', message: 'test', location: 'lib/a.rb', line: 1 }],
        undocumented: [{ element: 'Foo', location: 'lib/b.rb', line: 2 }],
        invalid_tags_order: [{ method_name: 'bar', order: 'param', location: 'lib/c.rb', line: 3 }]
      )

      result = described_class.new(data)

      expect(result.count).to eq(3)
    end
  end

  describe "#offenses?" do
    it 'returns false when there are no offenses' do
      result = described_class.new(empty_data)

      expect(result.offenses?).to be false
    end

    it 'returns true when there are offenses' do
      data = empty_data.merge(
        warnings: [{ name: 'Test', message: 'test', location: 'lib/a.rb', line: 1 }]
      )

      result = described_class.new(data)

      expect(result.offenses?).to be true
    end
  end

  describe "#clean?" do
    it 'returns true when there are no offenses' do
      result = described_class.new(empty_data)

      expect(result.clean?).to be true
    end

    it 'returns false when there are offenses' do
      data = empty_data.merge(
        warnings: [{ name: 'Test', message: 'test', location: 'lib/a.rb', line: 1 }]
      )

      result = described_class.new(data)

      expect(result.clean?).to be false
    end
  end

  describe "#statistics" do
    it 'returns zero counts for clean result' do
      result = described_class.new(empty_data)
      stats = result.statistics

      expect(stats[:error]).to eq(0)
      expect(stats[:warning]).to eq(0)
      expect(stats[:convention]).to eq(0)
      expect(stats[:total]).to eq(0)
    end

    it 'counts offenses by severity' do
      data = empty_data.merge(
        warnings: [
          { name: 'Test1', message: 'test', location: 'lib/a.rb', line: 1 },
          { name: 'Test2', message: 'test', location: 'lib/a.rb', line: 2 }
        ],
        undocumented: [
          { element: 'Foo', location: 'lib/b.rb', line: 3 }
        ],
        invalid_tags_order: [
          { method_name: 'bar', order: 'param', location: 'lib/c.rb', line: 4 }
        ]
      )

      result = described_class.new(data)
      stats = result.statistics

      expect(stats[:error]).to eq(2)
      expect(stats[:warning]).to eq(1)
      expect(stats[:convention]).to eq(1)
      expect(stats[:total]).to eq(4)
    end
  end

  describe "#exit_code" do
    let(:config) { Yard::Lint::Config.new }

    it 'returns 0 for clean result regardless of config' do
      result = described_class.new(empty_data)

      expect(result.exit_code(config)).to eq(0)
    end

    context 'when fail_on_severity is "never"' do
      before { config.fail_on_severity = 'never' }

      it 'returns 0 even with offenses' do
        data = empty_data.merge(
          warnings: [{ name: 'Test', message: 'test', location: 'lib/a.rb', line: 1 }]
        )
        result = described_class.new(data)

        expect(result.exit_code(config)).to eq(0)
      end
    end

    context 'when fail_on_severity is "error"' do
      before { config.fail_on_severity = 'error' }

      it 'returns 1 when there are errors' do
        data = empty_data.merge(
          warnings: [{ name: 'Test', message: 'test', location: 'lib/a.rb', line: 1 }]
        )
        result = described_class.new(data)

        expect(result.exit_code(config)).to eq(1)
      end

      it 'returns 0 when there are only warnings' do
        data = empty_data.merge(
          undocumented: [{ element: 'Foo', location: 'lib/b.rb', line: 2 }]
        )
        result = described_class.new(data)

        expect(result.exit_code(config)).to eq(0)
      end

      it 'returns 0 when there are only conventions' do
        data = empty_data.merge(
          invalid_tags_order: [
            { method_name: 'bar', order: 'param', location: 'lib/c.rb', line: 3 }
          ]
        )
        result = described_class.new(data)

        expect(result.exit_code(config)).to eq(0)
      end
    end

    context 'when fail_on_severity is "warning"' do
      before { config.fail_on_severity = 'warning' }

      it 'returns 1 when there are errors' do
        data = empty_data.merge(
          warnings: [{ name: 'Test', message: 'test', location: 'lib/a.rb', line: 1 }]
        )
        result = described_class.new(data)

        expect(result.exit_code(config)).to eq(1)
      end

      it 'returns 1 when there are warnings' do
        data = empty_data.merge(
          undocumented: [{ element: 'Foo', location: 'lib/b.rb', line: 2 }]
        )
        result = described_class.new(data)

        expect(result.exit_code(config)).to eq(1)
      end

      it 'returns 0 when there are only conventions' do
        data = empty_data.merge(
          invalid_tags_order: [
            { method_name: 'bar', order: 'param', location: 'lib/c.rb', line: 3 }
          ]
        )
        result = described_class.new(data)

        expect(result.exit_code(config)).to eq(0)
      end
    end

    context 'when fail_on_severity is "convention"' do
      before { config.fail_on_severity = 'convention' }

      it 'returns 1 for any offense type' do
        data = empty_data.merge(
          invalid_tags_order: [
            { method_name: 'bar', order: 'param', location: 'lib/c.rb', line: 3 }
          ]
        )
        result = described_class.new(data)

        expect(result.exit_code(config)).to eq(1)
      end
    end
  end
end

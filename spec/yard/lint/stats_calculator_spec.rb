# frozen_string_literal: true

RSpec.describe Yard::Lint::StatsCalculator do
  let(:config) { Yard::Lint::Config.new }
  let(:files) { ['/path/to/file1.rb', '/path/to/file2.rb'] }
  let(:calculator) { described_class.new(config, files) }

  describe '#initialize' do
    it 'stores config and files' do
      expect(calculator.config).to eq(config)
      expect(calculator.files).to eq(files)
    end

    it 'handles nil files gracefully' do
      calc = described_class.new(config, nil)
      expect(calc.files).to eq([])
    end
  end

  describe '#calculate' do
    context 'with empty file list' do
      let(:files) { [] }

      it 'returns 100% coverage' do
        result = calculator.calculate
        expect(result).to eq(
          total: 0,
          documented: 0,
          coverage: 100.0
        )
      end
    end

    context 'with valid YARD output' do
      let(:yard_output) do
        <<~OUTPUT
          method:doc
          method:doc
          method:undoc
          class:doc
          class:undoc
          module:doc
        OUTPUT
      end

      before do
        allow(calculator).to receive(:run_yard_stats_query).and_return(yard_output)
      end

      it 'calculates correct coverage' do
        result = calculator.calculate
        # 4 documented (2 methods + 1 class + 1 module) / 6 total = 66.67%
        expect(result[:total]).to eq(6)
        expect(result[:documented]).to eq(4)
        expect(result[:coverage]).to be_within(0.01).of(66.67)
      end
    end

    context 'with all documented objects' do
      let(:yard_output) do
        <<~OUTPUT
          method:doc
          class:doc
          module:doc
        OUTPUT
      end

      before do
        allow(calculator).to receive(:run_yard_stats_query).and_return(yard_output)
      end

      it 'returns 100% coverage' do
        result = calculator.calculate
        expect(result[:total]).to eq(3)
        expect(result[:documented]).to eq(3)
        expect(result[:coverage]).to eq(100.0)
      end
    end

    context 'with all undocumented objects' do
      let(:yard_output) do
        <<~OUTPUT
          method:undoc
          class:undoc
        OUTPUT
      end

      before do
        allow(calculator).to receive(:run_yard_stats_query).and_return(yard_output)
      end

      it 'returns 0% coverage' do
        result = calculator.calculate
        expect(result[:total]).to eq(2)
        expect(result[:documented]).to eq(0)
        expect(result[:coverage]).to eq(0.0)
      end
    end

    context 'when YARD command fails' do
      before do
        allow(calculator).to receive(:run_yard_stats_query).and_return('')
      end

      it 'returns default stats' do
        result = calculator.calculate
        expect(result).to eq(
          total: 0,
          documented: 0,
          coverage: 100.0
        )
      end
    end
  end

  describe '#parse_stats_output' do
    it 'parses valid output correctly' do
      output = <<~OUTPUT
        method:doc
        method:undoc
        method:undoc
        class:doc
        module:undoc
      OUTPUT

      result = calculator.send(:parse_stats_output, output)

      expect(result['method']).to eq(documented: 1, undocumented: 2)
      expect(result['class']).to eq(documented: 1, undocumented: 0)
      expect(result['module']).to eq(documented: 0, undocumented: 1)
    end

    it 'handles empty output' do
      result = calculator.send(:parse_stats_output, '')
      expect(result).to eq({})
    end

    it 'handles malformed lines gracefully' do
      output = <<~OUTPUT
        method:doc
        invalid_line
        class:doc
      OUTPUT

      result = calculator.send(:parse_stats_output, output)
      expect(result.keys).to contain_exactly('method', 'class')
    end

    it 'ignores lines with extra colons' do
      output = "method:doc:extra\n"
      result = calculator.send(:parse_stats_output, output)
      # Line is malformed (extra colon), should be ignored
      # Hash.new returns default value for non-existent keys
      expect(result['method']).to eq(documented: 0, undocumented: 0)
    end
  end

  describe '#calculate_coverage_percentage' do
    it 'calculates correct percentage' do
      stats = {
        'method' => { documented: 8, undocumented: 2 },
        'class' => { documented: 5, undocumented: 0 }
      }

      result = calculator.send(:calculate_coverage_percentage, stats)

      expect(result[:total]).to eq(15)
      expect(result[:documented]).to eq(13)
      expect(result[:coverage]).to be_within(0.01).of(86.67)
    end

    it 'returns 100% for empty stats' do
      stats = {}
      result = calculator.send(:calculate_coverage_percentage, stats)

      expect(result[:total]).to eq(0)
      expect(result[:documented]).to eq(0)
      expect(result[:coverage]).to eq(100.0)
    end

    it 'handles zero documented objects' do
      stats = {
        'method' => { documented: 0, undocumented: 10 }
      }

      result = calculator.send(:calculate_coverage_percentage, stats)

      expect(result[:total]).to eq(10)
      expect(result[:documented]).to eq(0)
      expect(result[:coverage]).to eq(0.0)
    end
  end

  describe '#build_stats_query' do
    it 'returns valid YARD query' do
      query = calculator.send(:build_stats_query)
      expect(query).to include('object.type.to_s')
      expect(query).to include('object.docstring.all.empty?')
      expect(query).to include('doc')
      expect(query).to include('undoc')
    end
  end
end

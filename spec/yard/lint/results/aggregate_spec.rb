# frozen_string_literal: true

RSpec.describe Yard::Lint::Results::Aggregate do
  let(:result1) do
    instance_double(
      Yard::Lint::Results::Base,
      offenses: [
        { severity: 'error', type: 'line', name: 'Error1', message: 'msg1',
          location: 'file1.rb', location_line: 1 },
        { severity: 'warning', type: 'method', name: 'Warning1', message: 'msg2',
          location: 'file2.rb', location_line: 2 }
      ]
    )
  end

  let(:result2) do
    instance_double(
      Yard::Lint::Results::Base,
      offenses: [
        { severity: 'convention', type: 'line', name: 'Convention1', message: 'msg3',
          location: 'file3.rb', location_line: 3 }
      ]
    )
  end

  let(:result3) do
    instance_double(Yard::Lint::Results::Base, offenses: [])
  end

  let(:config) do
    instance_double(Yard::Lint::Config, fail_on_severity: 'warning')
  end

  let(:aggregate) { described_class.new([result1, result2, result3], config) }

  describe '#initialize' do
    it 'accepts array of results' do
      expect { described_class.new([result1, result2], config) }.not_to raise_error
    end

    it 'handles single result' do
      aggregate = described_class.new(result1, config)
      expect(aggregate.offenses.size).to eq(2)
    end

    it 'handles nil results' do
      aggregate = described_class.new(nil, config)
      expect(aggregate.offenses).to eq([])
    end

    it 'handles empty array' do
      aggregate = described_class.new([], config)
      expect(aggregate.offenses).to eq([])
    end

    it 'stores config' do
      expect(aggregate.config).to eq(config)
    end
  end

  describe '#offenses' do
    it 'flattens all offenses from all results' do
      expect(aggregate.offenses).to be_an(Array)
      expect(aggregate.offenses.size).to eq(3)
    end

    it 'preserves offense structure' do
      offense = aggregate.offenses.first
      expect(offense).to include(
        :severity,
        :type,
        :name,
        :message,
        :location,
        :location_line
      )
    end

    it 'includes offenses from all results' do
      expect(aggregate.offenses.map { |o| o[:name] }).to contain_exactly(
        'Error1', 'Warning1', 'Convention1'
      )
    end
  end

  describe '#count' do
    it 'returns total number of offenses' do
      expect(aggregate.count).to eq(3)
    end

    it 'returns 0 when no offenses' do
      empty_aggregate = described_class.new([result3], config)
      expect(empty_aggregate.count).to eq(0)
    end
  end

  describe '#clean?' do
    it 'returns false when offenses exist' do
      expect(aggregate.clean?).to be(false)
    end

    it 'returns true when no offenses' do
      empty_aggregate = described_class.new([result3], config)
      expect(empty_aggregate.clean?).to be(true)
    end
  end

  describe '#statistics' do
    it 'counts offenses by severity' do
      stats = aggregate.statistics
      expect(stats).to be_a(Hash)
      expect(stats[:error]).to eq(1)
      expect(stats[:warning]).to eq(1)
      expect(stats[:convention]).to eq(1)
    end

    it 'initializes all severity counts to 0' do
      empty_aggregate = described_class.new([], config)
      stats = empty_aggregate.statistics
      expect(stats[:error]).to eq(0)
      expect(stats[:warning]).to eq(0)
      expect(stats[:convention]).to eq(0)
    end

    it 'handles multiple offenses of same severity' do
      result_with_multiple = instance_double(
        Yard::Lint::Results::Base,
        offenses: [
          { severity: 'error', type: 'line', name: 'Error1', message: 'msg',
            location: 'f.rb', location_line: 1 },
          { severity: 'error', type: 'line', name: 'Error2', message: 'msg',
            location: 'f.rb', location_line: 2 }
        ]
      )
      agg = described_class.new([result_with_multiple], config)
      expect(agg.statistics[:error]).to eq(2)
    end
  end

  describe '#exit_code' do
    context 'when fail_on_severity is "error"' do
      let(:config) { instance_double(Yard::Lint::Config, fail_on_severity: 'error', min_coverage: nil) }

      it 'returns 1 if errors exist' do
        expect(aggregate.exit_code).to eq(1)
      end

      it 'returns 0 if only warnings exist' do
        agg = described_class.new([result2], config)
        expect(agg.exit_code).to eq(0)
      end

      it 'returns 0 if no offenses' do
        agg = described_class.new([], config)
        expect(agg.exit_code).to eq(0)
      end
    end

    context 'when fail_on_severity is "warning"' do
      let(:config) { instance_double(Yard::Lint::Config, fail_on_severity: 'warning', min_coverage: nil) }

      it 'returns 1 if errors exist' do
        expect(aggregate.exit_code).to eq(1)
      end

      it 'returns 1 if warnings exist' do
        warning_result = instance_double(
          Yard::Lint::Results::Base,
          offenses: [
            { severity: 'warning', type: 'line', name: 'Warn', message: 'msg',
              location: 'f.rb', location_line: 1 }
          ]
        )
        agg = described_class.new([warning_result], config)
        expect(agg.exit_code).to eq(1)
      end

      it 'returns 0 if only conventions exist' do
        agg = described_class.new([result2], config)
        allow(result2).to receive(:offenses).and_return(
          [
            {
              severity: 'convention',
              type: 'line',
              name: 'Conv',
              message: 'msg',
              location: 'f.rb',
              location_line: 1
            }
          ]
        )
        expect(agg.exit_code).to eq(0)
      end

      it 'returns 0 if no offenses' do
        agg = described_class.new([], config)
        expect(agg.exit_code).to eq(0)
      end
    end

    context 'when fail_on_severity is "convention"' do
      let(:config) { instance_double(Yard::Lint::Config, fail_on_severity: 'convention', min_coverage: nil) }

      it 'returns 1 if any offenses exist' do
        expect(aggregate.exit_code).to eq(1)
      end

      it 'returns 0 if no offenses' do
        agg = described_class.new([], config)
        expect(agg.exit_code).to eq(0)
      end
    end

    context 'when fail_on_severity is unknown' do
      let(:config) { instance_double(Yard::Lint::Config, fail_on_severity: 'unknown', min_coverage: nil) }

      it 'returns 0' do
        expect(aggregate.exit_code).to eq(0)
      end
    end
  end
end

# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::ExampleStyle::RubocopRunner do
  describe '#run' do
    let(:runner) { described_class.new(linter: :rubocop, disabled_cops: [], skip_patterns: []) }

    context 'with skip patterns' do
      let(:runner) do
        described_class.new(
          linter: :rubocop,
          disabled_cops: [],
          skip_patterns: ['/skip-lint/i', '/bad code/i']
        )
      end

      it 'skips examples matching skip patterns (case insensitive)' do
        result = runner.run('user = User.new', 'Bad code (skip-lint)')
        expect(result).to eq([])
      end

      it 'skips examples matching alternative pattern' do
        result = runner.run('user = User.new', 'Example showing bad code')
        expect(result).to eq([])
      end

      it 'does not skip examples that do not match patterns' do
        allow(Open3).to receive(:capture3).and_return(['{"files":[]}', '', double(success?: true)])
        result = runner.run('user = User.new', 'Valid example')
        expect(result).to eq([])
      end
    end

    context 'with code cleaning' do
      it 'removes output indicators (#=>)' do
        code = <<~RUBY
          result = User.new
          result.name  # => "John"
        RUBY

        expected_cleaned_code = "result = User.new\nresult.name"

        expect(Open3).to receive(:capture3) do |*args, **kwargs|
          expect(kwargs[:stdin_data].strip).to eq(expected_cleaned_code.strip)
          ['{"files":[]}', '', double(success?: true)]
        end

        runner.run(code, 'Example')
      end

      it 'returns empty array for empty code' do
        result = runner.run('', 'Example')
        expect(result).to eq([])
      end

      it 'returns empty array for nil code' do
        result = runner.run(nil, 'Example')
        expect(result).to eq([])
      end

      it 'returns empty array for whitespace-only code' do
        result = runner.run("   \n  \n  ", 'Example')
        expect(result).to eq([])
      end
    end

    context 'with RuboCop linter' do
      let(:runner) do
        described_class.new(
          linter: :rubocop,
          disabled_cops: ['Style/FrozenStringLiteralComment'],
          skip_patterns: []
        )
      end

      it 'runs rubocop with disabled cops' do
        code = 'user = User.new'

        expect(Open3).to receive(:capture3) do |*args, **_kwargs|
          expect(args).to include('rubocop')
          expect(args).to include('--format', 'json')
          expect(args).to include('--stdin', 'example.rb')
          expect(args).to include('--except', 'Style/FrozenStringLiteralComment')
          ['{"files":[]}', '', double(success?: true)]
        end

        runner.run(code, 'Example')
      end

      it 'parses RuboCop JSON output correctly' do
        code = 'user = User.new'
        rubocop_output = {
          'files' => [
            {
              'offenses' => [
                {
                  'cop_name' => 'Style/StringLiterals',
                  'message' => 'Prefer single-quoted strings',
                  'severity' => 'convention',
                  'location' => { 'line' => 1, 'column' => 10 }
                }
              ]
            }
          ]
        }.to_json

        allow(Open3).to receive(:capture3).and_return([rubocop_output, '', double(success?: true)])

        result = runner.run(code, 'Example')
        expect(result).to eq([
          {
            cop_name: 'Style/StringLiterals',
            message: 'Prefer single-quoted strings',
            line: 1,
            column: 10,
            severity: 'convention'
          }
        ])
      end

      it 'handles empty RuboCop output' do
        allow(Open3).to receive(:capture3).and_return(['', '', double(success?: true)])
        result = runner.run('user = User.new', 'Example')
        expect(result).to eq([])
      end

      it 'handles missing rubocop command' do
        allow(Open3).to receive(:capture3).and_raise(Errno::ENOENT)
        result = runner.run('user = User.new', 'Example')
        expect(result).to eq([])
      end
    end

    context 'with StandardRB linter' do
      let(:runner) do
        described_class.new(
          linter: :standard,
          disabled_cops: [],
          skip_patterns: []
        )
      end

      it 'runs standardrb command' do
        code = 'user = User.new'

        expect(Open3).to receive(:capture3) do |*args, **_kwargs|
          expect(args).to include('standardrb')
          expect(args).to include('--format', 'json')
          expect(args).to include('--stdin', 'example.rb')
          ['{"files":[]}', '', double(success?: true)]
        end

        runner.run(code, 'Example')
      end

      it 'parses StandardRB JSON output correctly' do
        code = 'user = User.new'
        standard_output = {
          'files' => [
            {
              'offenses' => [
                {
                  'cop_name' => 'Style/StringLiterals',
                  'message' => 'Prefer single-quoted strings',
                  'severity' => 'convention',
                  'location' => { 'line' => 1, 'column' => 10 }
                }
              ]
            }
          ]
        }.to_json

        allow(Open3).to receive(:capture3).and_return([standard_output, '', double(success?: true)])

        result = runner.run(code, 'Example')
        expect(result).to eq([
          {
            cop_name: 'Style/StringLiterals',
            message: 'Prefer single-quoted strings',
            line: 1,
            column: 10,
            severity: 'convention'
          }
        ])
      end

      it 'handles missing standardrb command' do
        allow(Open3).to receive(:capture3).and_raise(Errno::ENOENT)
        result = runner.run('user = User.new', 'Example')
        expect(result).to eq([])
      end
    end

    context 'with error handling' do
      let(:runner) { described_class.new(linter: :rubocop, disabled_cops: [], skip_patterns: []) }

      it 'handles JSON parse errors gracefully' do
        allow(Open3).to receive(:capture3).and_return(['invalid json', '', double(success?: true)])
        result = runner.run('user = User.new', 'Example')
        expect(result).to eq([])
      end

      it 'handles general errors gracefully' do
        allow(Open3).to receive(:capture3).and_raise(StandardError.new('Something went wrong'))
        result = runner.run('user = User.new', 'Example')
        expect(result).to eq([])
      end
    end
  end
end

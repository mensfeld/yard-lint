# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector do
  describe '.detect' do
    let(:temp_dir) { Dir.mktmpdir }

    after do
      FileUtils.rm_rf(temp_dir)
    end

    context 'when linter is explicitly set to none' do
      it 'returns :none' do
        result = described_class.detect('none', project_root: temp_dir)
        expect(result).to eq(:none)
      end
    end

    context 'when linter is explicitly set to rubocop' do
      it 'returns :rubocop if rubocop is available' do
        allow(described_class).to receive(:rubocop_available?).and_return(true)
        result = described_class.detect('rubocop', project_root: temp_dir)
        expect(result).to eq(:rubocop)
      end

      it 'returns :none if rubocop is not available' do
        allow(described_class).to receive(:rubocop_available?).and_return(false)
        result = described_class.detect('rubocop', project_root: temp_dir)
        expect(result).to eq(:none)
      end
    end

    context 'when linter is explicitly set to standard' do
      it 'returns :standard if standard is available' do
        allow(described_class).to receive(:standard_available?).and_return(true)
        result = described_class.detect('standard', project_root: temp_dir)
        expect(result).to eq(:standard)
      end

      it 'returns :none if standard is not available' do
        allow(described_class).to receive(:standard_available?).and_return(false)
        result = described_class.detect('standard', project_root: temp_dir)
        expect(result).to eq(:none)
      end
    end

    context 'with auto-detection' do
      before do
        allow(described_class).to receive(:rubocop_available?).and_return(false)
        allow(described_class).to receive(:standard_available?).and_return(false)
      end

      it 'detects standard from .standard.yml' do
        File.write(File.join(temp_dir, '.standard.yml'), 'parallel: true')
        allow(described_class).to receive(:standard_available?).and_return(true)

        result = described_class.detect('auto', project_root: temp_dir)
        expect(result).to eq(:standard)
      end

      it 'detects rubocop from .rubocop.yml' do
        File.write(File.join(temp_dir, '.rubocop.yml'), 'AllCops:')
        allow(described_class).to receive(:rubocop_available?).and_return(true)

        result = described_class.detect('auto', project_root: temp_dir)
        expect(result).to eq(:rubocop)
      end

      it 'prefers standard over rubocop when both configs exist' do
        File.write(File.join(temp_dir, '.standard.yml'), 'parallel: true')
        File.write(File.join(temp_dir, '.rubocop.yml'), 'AllCops:')
        allow(described_class).to receive(:standard_available?).and_return(true)
        allow(described_class).to receive(:rubocop_available?).and_return(true)

        result = described_class.detect('auto', project_root: temp_dir)
        expect(result).to eq(:standard)
      end

      it 'detects standard from Gemfile' do
        File.write(File.join(temp_dir, 'Gemfile'), "gem 'standard'")
        allow(described_class).to receive(:standard_available?).and_return(true)

        result = described_class.detect('auto', project_root: temp_dir)
        expect(result).to eq(:standard)
      end

      it 'detects rubocop from Gemfile' do
        File.write(File.join(temp_dir, 'Gemfile'), "gem 'rubocop'")
        allow(described_class).to receive(:rubocop_available?).and_return(true)

        result = described_class.detect('auto', project_root: temp_dir)
        expect(result).to eq(:rubocop)
      end

      it 'detects standard from Gemfile.lock' do
        File.write(File.join(temp_dir, 'Gemfile.lock'), "  standard (1.0.0)")
        allow(described_class).to receive(:standard_available?).and_return(true)

        result = described_class.detect('auto', project_root: temp_dir)
        expect(result).to eq(:standard)
      end

      it 'detects rubocop from Gemfile.lock' do
        File.write(File.join(temp_dir, 'Gemfile.lock'), "  rubocop (1.0.0)")
        allow(described_class).to receive(:rubocop_available?).and_return(true)

        result = described_class.detect('auto', project_root: temp_dir)
        expect(result).to eq(:rubocop)
      end

      it 'returns :none when no linter is detected' do
        result = described_class.detect('auto', project_root: temp_dir)
        expect(result).to eq(:none)
      end
    end
  end

  describe '.rubocop_available?' do
    it 'returns true if rubocop can be required' do
      allow(described_class).to receive(:require).with('rubocop').and_return(true)
      expect(described_class.rubocop_available?).to be true
    end

    it 'returns false if rubocop cannot be required' do
      allow(described_class).to receive(:require).with('rubocop').and_raise(LoadError)
      expect(described_class.rubocop_available?).to be false
    end
  end

  describe '.standard_available?' do
    it 'returns true if standard can be required' do
      allow(described_class).to receive(:require).with('standard').and_return(true)
      expect(described_class.standard_available?).to be true
    end

    it 'returns false if standard cannot be required' do
      allow(described_class).to receive(:require).with('standard').and_raise(LoadError)
      expect(described_class.standard_available?).to be false
    end
  end
end

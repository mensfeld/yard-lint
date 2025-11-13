# frozen_string_literal: true

RSpec.describe 'CLI Integration Tests' do
  let(:bin_path) { File.expand_path('../../bin/yard-lint', __dir__) }

  describe '--version flag' do
    it 'displays the version number' do
      output = `#{bin_path} --version 2>&1`
      expect($?.success?).to be true
      expect(output).to match(/yard-lint \d+\.\d+\.\d+/)
      expect(output.strip).to eq("yard-lint #{Yard::Lint::VERSION}")
    end

    it 'exits successfully' do
      `#{bin_path} --version 2>&1`
      expect($?.exitstatus).to eq(0)
    end
  end

  describe '-v flag' do
    it 'displays the version number' do
      output = `#{bin_path} -v 2>&1`
      expect($?.success?).to be true
      expect(output).to match(/yard-lint \d+\.\d+\.\d+/)
      expect(output.strip).to eq("yard-lint #{Yard::Lint::VERSION}")
    end

    it 'exits successfully' do
      `#{bin_path} -v 2>&1`
      expect($?.exitstatus).to eq(0)
    end
  end
end

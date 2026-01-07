RSpec.describe 'Macro Integration' do
  let(:fixtures_path) do
    [
      File.expand_path('fixtures/macro_a.rb', __dir__),
      File.expand_path('fixtures/macro_b.rb', __dir__)
    ]
  end

  describe 'Macro attachment and expansion' do
    let(:config) { test_config }

    it 'correctly attaches and expands macros across files' do
      result = Yard::Lint.run(path: fixtures_path, config: config, progress: false)

      expect(result.count).to be == 0
    end

    it 'correctly attaches and expands macros across files reversed order' do
      result = Yard::Lint.run(path: fixtures_path.reverse, config: config, progress: false)

      expect(result.count).to be == 0
    end
  end
end

# frozen_string_literal: true

# Proves that a category-level Enabled setting (e.g. `Documentation:
# { Enabled: false }`) is honored. It previously passed validation but was
# silently ignored, so the Documentation validators still ran.
describe 'Category-level config' do
  attr_reader :fixture_path

  before do
    @fixture_path = File.expand_path('../fixtures/category_config.rb', __dir__)
  end

  it 'disables a whole category with Enabled: false' do
    config = Yard::Lint::Config.new(
      'AllValidators' => { 'Exclude' => [] },
      'Documentation' => { 'Enabled' => false }
    )

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    documentation = result.offenses.select { |o| o[:validator].to_s.start_with?('Documentation/') }
    assert_empty(documentation, 'Documentation validators ran despite category Enabled: false')
  end

  it 'leaves the category enabled by default' do
    config = Yard::Lint::Config.new('AllValidators' => { 'Exclude' => [] })

    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    documentation = result.offenses.select { |o| o[:validator].to_s.start_with?('Documentation/') }
    refute_empty(documentation, 'expected Documentation offenses when the category is enabled')
  end
end

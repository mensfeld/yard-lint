# frozen_string_literal: true

RSpec.describe 'TagTypePosition Integration' do
  let(:fixture_path) { 'spec/fixtures/tag_type_position_examples.rb' }
  let(:config) do
    Yard::Lint::Config.new do |c|
      c.send(:set_validator_config, 'Tags/TagTypePosition', 'Enabled', true)
    end
  end

  it 'detects type before parameter name (violates YARD standard)' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
    offenses = result.offenses.select { |o| o[:name] == 'TagTypePosition' }

    # Should find violations in:
    # - InvalidTypePosition: @param [String] name, @param [Integer] age (2 violations)
    # - MixedTypePosition: @param [Hash] opts (1 violation)
    expect(offenses.size).to eq(3)
  end

  it 'provides helpful messages' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
    offense = result.offenses.find { |o| o[:name] == 'TagTypePosition' }

    if offense
      expect(offense[:message]).to include('after parameter name')
      expect(offense[:message]).to include('@')
    end
  end
end

# frozen_string_literal: true

require 'test_helper'

describe 'Tag Type Position' do
  attr_reader :fixture_path, :config

  before do
    @fixture_path = File.expand_path('../fixtures/tag_type_position_examples.rb', __dir__)
    @config = test_config do |c|
      c.set_validator_config('Tags/TagTypePosition', 'Enabled', true)
      end
  end

  it 'detects type before parameter name violates yard standard' do
    result = Yard::Lint.run(path: @fixture_path, config: @config, progress: false)
    offenses = result.offenses.select { |o| o[:name] == 'TagTypePosition' }

    # Should find violations in:
    # - InvalidTypePosition: @param [String] name, @param [Integer] age (2 violations)
    # - MixedTypePosition: @param [Hash] opts (1 violation)
    assert_equal(3, offenses.size)
  end

  it 'provides helpful messages' do
    result = Yard::Lint.run(path: @fixture_path, config: @config, progress: false)
    offense = result.offenses.find { |o| o[:name] == 'TagTypePosition' }

    if offense
      assert_includes(offense[:message], 'after parameter name')
      assert_includes(offense[:message], '@')
      end
  end
end


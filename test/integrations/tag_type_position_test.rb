# frozen_string_literal: true

require 'test_helper'

class TagTypePositionIntegrationTest < Minitest::Test
  attr_reader :config

  def setup
    @fixture_path = File.expand_path('../fixtures/tag_type_position_examples.rb', __dir__)
    @config = test_config do |c|
      c.send(:set_validator_config, 'Tags/TagTypePosition', 'Enabled', true)
      end
  end

  def test_detects_type_before_parameter_name_violates_yard_standard
    result = Yard::Lint.run(path: @fixture_path, config: @config, progress: false)
    offenses = result.offenses.select { |o| o[:name] == 'TagTypePosition' }

    # Should find violations in:
    # - InvalidTypePosition: @param [String] name, @param [Integer] age (2 violations)
    # - MixedTypePosition: @param [Hash] opts (1 violation)
    assert_equal(3, offenses.size)
  end

  def test_provides_helpful_messages
    result = Yard::Lint.run(path: @fixture_path, config: @config, progress: false)
    offense = result.offenses.find { |o| o[:name] == 'TagTypePosition' }

    if offense
      assert_includes(offense[:message], 'after parameter name')
      assert_includes(offense[:message], '@')
      end
  end
end

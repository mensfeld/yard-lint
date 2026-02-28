# frozen_string_literal: true

require 'test_helper'

class TagsOrderIntegrationTest < Minitest::Test
  attr_reader :config, :fixture_path

  def setup
    @fixture_path = File.expand_path('../fixtures/tag_order_examples.rb', __dir__)
    @config = test_config do |c|
      c.send(:set_validator_config, 'Tags/Order', 'Enabled', true)
    end
  end

  def test_detecting_invalid_tag_order_detects_return_before_param
    result = Yard::Lint.run(path: fixture_path, config:, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'InvalidTagOrder' &&
        o[:message].include?('return_before_param')
    end

    refute_empty(offenses)
    assert_includes(offenses.first[:message], 'param')
    assert_includes(offenses.first[:message], 'return')
  end

  def test_detecting_invalid_tag_order_detects_note_before_return
    result = Yard::Lint.run(path: fixture_path, config:, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'InvalidTagOrder' &&
        o[:message].include?('note_before_return')
    end

    refute_empty(offenses)
  end

  def test_detecting_invalid_tag_order_detects_note_before_example
    result = Yard::Lint.run(path: fixture_path, config:, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'InvalidTagOrder' &&
        o[:message].include?('note_before_example')
    end

    refute_empty(offenses)
  end

  def test_detecting_invalid_tag_order_detects_see_before_return
    result = Yard::Lint.run(path: fixture_path, config:, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'InvalidTagOrder' &&
        o[:message].include?('see_before_return')
    end

    refute_empty(offenses)
  end

  def test_detecting_invalid_tag_order_detects_todo_before_note
    result = Yard::Lint.run(path: fixture_path, config:, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'InvalidTagOrder' &&
        o[:message].include?('todo_before_note')
    end

    refute_empty(offenses)
  end

  def test_detecting_invalid_tag_order_detects_yield_tags_in_wrong_order
    result = Yard::Lint.run(path: fixture_path, config:, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'InvalidTagOrder' &&
        o[:message].include?('yield_tags_wrong_order')
    end

    refute_empty(offenses)
  end

  def test_detecting_invalid_tag_order_detects_raise_before_return
    result = Yard::Lint.run(path: fixture_path, config:, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'InvalidTagOrder' &&
        o[:message].include?('raise_before_return')
    end

    refute_empty(offenses)
  end

  def test_correct_tag_order_does_not_flag_methods_with_correct_full_tag_order
    result = Yard::Lint.run(path: fixture_path, config:, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'InvalidTagOrder' &&
        o[:message].include?('correct_full_order')
    end

    assert_empty(offenses)
  end

  def test_correct_tag_order_does_not_flag_methods_with_correct_partial_tag_order
    result = Yard::Lint.run(path: fixture_path, config:, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'InvalidTagOrder' &&
        o[:message].include?('correct_partial_order')
    end

    assert_empty(offenses)
  end

  def test_correct_tag_order_does_not_flag_simple_param_return_order
    result = Yard::Lint.run(path: fixture_path, config:, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'InvalidTagOrder' &&
        o[:message].include?('simple_correct_order')
    end

    assert_empty(offenses)
  end

  def test_consecutive_same_tags_does_not_flag_multiple_consecutive_param_tags
    result = Yard::Lint.run(path: fixture_path, config:, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'InvalidTagOrder' &&
        o[:message].include?('multiple_params')
    end

    assert_empty(offenses)
  end

  def test_consecutive_same_tags_does_not_flag_multiple_consecutive_note_tags
    result = Yard::Lint.run(path: fixture_path, config:, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'InvalidTagOrder' &&
        o[:message].include?('multiple_notes')
    end

    assert_empty(offenses)
  end

  def test_consecutive_same_tags_does_not_flag_multiple_consecutive_example_tags
    result = Yard::Lint.run(path: fixture_path, config:, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'InvalidTagOrder' &&
        o[:message].include?('multiple_examples')
    end

    assert_empty(offenses)
  end

  def test_enforced_order_configuration_uses_the_full_default_order_from_config
    defaults = Yard::Lint::Validators::Tags::Order::Config.defaults
    expected_order = %w[param option yield yieldparam yieldreturn return raise see example note todo]

    assert_equal(expected_order, defaults['EnforcedOrder'])
  end

  def test_when_disabled_does_not_run_validation
    disabled_config = test_config do |c|
      c.send(:set_validator_config, 'Tags/Order', 'Enabled', false)
    end

    result = Yard::Lint.run(path: fixture_path, config: disabled_config, progress: false)

    order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
    assert_empty(order_offenses)
  end
end

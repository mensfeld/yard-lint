# frozen_string_literal: true

require 'test_helper'


describe 'Tag Order' do
  attr_reader :fixture_path, :config


  before do
    @fixture_path = File.expand_path('../fixtures/tag_order_examples.rb', __dir__)
    @config = test_config do |c|
      c.set_validator_config('Tags/Order', 'Enabled', true)
    end
  end

  it 'detecting invalid tag order detects return before param' do
    result = Yard::Lint.run(path: fixture_path, config:, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'InvalidTagOrder' &&
        o[:message].include?('return_before_param')
    end

    refute_empty(offenses)
    assert_includes(offenses.first[:message], 'param')
    assert_includes(offenses.first[:message], 'return')
  end

  it 'detecting invalid tag order detects note before return' do
    result = Yard::Lint.run(path: fixture_path, config:, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'InvalidTagOrder' &&
        o[:message].include?('note_before_return')
    end

    refute_empty(offenses)
  end

  it 'detecting invalid tag order detects note before example' do
    result = Yard::Lint.run(path: fixture_path, config:, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'InvalidTagOrder' &&
        o[:message].include?('note_before_example')
    end

    refute_empty(offenses)
  end

  it 'detecting invalid tag order detects see before return' do
    result = Yard::Lint.run(path: fixture_path, config:, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'InvalidTagOrder' &&
        o[:message].include?('see_before_return')
    end

    refute_empty(offenses)
  end

  it 'detecting invalid tag order detects todo before note' do
    result = Yard::Lint.run(path: fixture_path, config:, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'InvalidTagOrder' &&
        o[:message].include?('todo_before_note')
    end

    refute_empty(offenses)
  end

  it 'detecting invalid tag order detects yield tags in wrong order' do
    result = Yard::Lint.run(path: fixture_path, config:, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'InvalidTagOrder' &&
        o[:message].include?('yield_tags_wrong_order')
    end

    refute_empty(offenses)
  end

  it 'detecting invalid tag order detects raise before return' do
    result = Yard::Lint.run(path: fixture_path, config:, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'InvalidTagOrder' &&
        o[:message].include?('raise_before_return')
    end

    refute_empty(offenses)
  end

  it 'correct tag order does not flag methods with correct full tag order' do
    result = Yard::Lint.run(path: fixture_path, config:, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'InvalidTagOrder' &&
        o[:message].include?('correct_full_order')
    end

    assert_empty(offenses)
  end

  it 'correct tag order does not flag methods with correct partial tag order' do
    result = Yard::Lint.run(path: fixture_path, config:, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'InvalidTagOrder' &&
        o[:message].include?('correct_partial_order')
    end

    assert_empty(offenses)
  end

  it 'correct tag order does not flag simple param return order' do
    result = Yard::Lint.run(path: fixture_path, config:, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'InvalidTagOrder' &&
        o[:message].include?('simple_correct_order')
    end

    assert_empty(offenses)
  end

  it 'consecutive same tags does not flag multiple consecutive param tags' do
    result = Yard::Lint.run(path: fixture_path, config:, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'InvalidTagOrder' &&
        o[:message].include?('multiple_params')
    end

    assert_empty(offenses)
  end

  it 'consecutive same tags does not flag multiple consecutive note tags' do
    result = Yard::Lint.run(path: fixture_path, config:, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'InvalidTagOrder' &&
        o[:message].include?('multiple_notes')
    end

    assert_empty(offenses)
  end

  it 'consecutive same tags does not flag multiple consecutive example tags' do
    result = Yard::Lint.run(path: fixture_path, config:, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'InvalidTagOrder' &&
        o[:message].include?('multiple_examples')
    end

    assert_empty(offenses)
  end

  it 'enforced order configuration uses the full default order from config' do
    defaults = Yard::Lint::Validators::Tags::Order::Config.defaults
    expected_order = %w[param option yield yieldparam yieldreturn return raise see example note todo]

    assert_equal(expected_order, defaults['EnforcedOrder'])
  end

  it 'when disabled does not run validation' do
    disabled_config = test_config do |c|
      c.set_validator_config('Tags/Order', 'Enabled', false)
    end

    result = Yard::Lint.run(path: fixture_path, config: disabled_config, progress: false)

    order_offenses = result.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
    assert_empty(order_offenses)
  end
end

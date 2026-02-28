# frozen_string_literal: true

require 'test_helper'

class MeaninglessTagIntegrationTest < Minitest::Test
  attr_reader :config, :fixture_path

  def setup
    @fixture_path = File.expand_path('../fixtures/meaningless_tag_examples.rb', __dir__)
    @config = test_config do |c|
      c.send(:set_validator_config, 'Tags/MeaninglessTag', 'Enabled', true)
    end
  end

  def test_detecting_meaningless_tags_finds_param_tags_on_classes
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    param_on_class = result.offenses.select do |o|
      o[:name] == 'MeaninglessTag' &&
        o[:message].include?('@param') &&
        o[:message].include?('class')
    end

    refute_empty(param_on_class)
  end

  def test_detecting_meaningless_tags_finds_option_tags_on_modules
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    option_on_module = result.offenses.select do |o|
      o[:name] == 'MeaninglessTag' &&
        o[:message].include?('@option') &&
        o[:message].include?('module')
    end

    refute_empty(option_on_module)
  end

  def test_detecting_meaningless_tags_finds_param_tags_on_constants
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    param_on_constant = result.offenses.select do |o|
      o[:name] == 'MeaninglessTag' &&
        o[:message].include?('@param') &&
        o[:message].include?('constant')
    end

    refute_empty(param_on_constant)
  end

  def test_detecting_meaningless_tags_does_not_flag_valid_param_tags_on_methods
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    # All offenses should be on classes/modules/constants, not methods
    offenses = result.offenses.select { |o| o[:name] == 'MeaninglessTag' }

    offenses.each do |offense|
      # Check that the offense is about a class, module, or constant (not a method)
      assert_match(/on a (class|module|constant)/, offense[:message])
    end
  end

  def test_detecting_meaningless_tags_provides_helpful_error_messages
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find { |o| o[:name] == 'MeaninglessTag' }
    refute_nil(offense)
    assert_includes(offense[:message], 'meaningless')
    assert_includes(offense[:message], 'only makes sense on methods')
  end

  def test_when_disabled_does_not_run_validation
    disabled_config = test_config do |c|
      c.send(:set_validator_config, 'Tags/MeaninglessTag', 'Enabled', false)
    end

    result = Yard::Lint.run(path: fixture_path, config: disabled_config, progress: false)

    meaningless_tag_offenses = result.offenses.select { |o| o[:name] == 'MeaninglessTag' }
    assert_empty(meaningless_tag_offenses)
  end
end

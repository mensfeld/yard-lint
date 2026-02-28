# frozen_string_literal: true

require 'test_helper'

class EmptyCommentLineIntegrationTest < Minitest::Test
  attr_reader :config, :fixture_path

  def setup
    @fixture_path = File.expand_path('../fixtures/empty_comment_lines.rb', __dir__)
    @config = test_config do |c|
      c.send(:set_validator_config, 'Documentation/EmptyCommentLine', 'Enabled', true)
    end
  end

  def test_detecting_empty_comment_lines_finds_leading_empty_comment_lines
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    leading_offenses = result.offenses.select do |o|
      o[:name] == 'EmptyCommentLine' &&
        o[:message].include?('leading')
    end

    # Should find in: LeadingEmptyClass, BothEmptyClass, leading_method
    assert_equal(3, leading_offenses.size)
  end

  def test_detecting_empty_comment_lines_finds_trailing_empty_comment_lines
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    trailing_offenses = result.offenses.select do |o|
      o[:name] == 'EmptyCommentLine' &&
        o[:message].include?('trailing')
    end

    # Should find in: TrailingEmptyClass, BothEmptyClass, trailing_method,
    # multiple_trailing (2 lines)
    assert_equal(5, trailing_offenses.size)
  end

  def test_detecting_empty_comment_lines_does_not_flag_empty_lines_between_sections
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    # valid_with_spacing has empty lines between description and @param
    # and between @param and @return - these should NOT be flagged
    valid_spacing_offenses = result.offenses.select do |o|
      o[:name] == 'EmptyCommentLine' &&
        o[:location]&.include?('valid_with_spacing')
    end

    assert_empty(valid_spacing_offenses)
  end

  def test_detecting_empty_comment_lines_provides_helpful_error_messages
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find { |o| o[:name] == 'EmptyCommentLine' }

    refute_nil(offense)
    assert_match(/Empty (leading|trailing) comment line/, offense[:message])
    assert_includes(offense[:message], 'line')
  end

  def test_configuration_options_when_only_checking_leading_only_finds_leading_empty_lines
    leading_only_config = test_config do |c|
      c.send(:set_validator_config, 'Documentation/EmptyCommentLine', 'Enabled', true)
      c.send(:set_validator_config, 'Documentation/EmptyCommentLine', 'EnabledPatterns', {
               'Leading' => true,
               'Trailing' => false
             })
    end

    result = Yard::Lint.run(path: fixture_path, config: leading_only_config, progress: false)

    offenses = result.offenses.select { |o| o[:name] == 'EmptyCommentLine' }

    offenses.each do |offense|
      assert_includes(offense[:message], 'leading')
      refute_includes(offense[:message], 'trailing')
    end
  end

  def test_configuration_options_when_only_checking_trailing_only_finds_trailing_empty_lines
    trailing_only_config = test_config do |c|
      c.send(:set_validator_config, 'Documentation/EmptyCommentLine', 'Enabled', true)
      c.send(:set_validator_config, 'Documentation/EmptyCommentLine', 'EnabledPatterns', {
               'Leading' => false,
               'Trailing' => true
             })
    end

    result = Yard::Lint.run(path: fixture_path, config: trailing_only_config, progress: false)

    offenses = result.offenses.select { |o| o[:name] == 'EmptyCommentLine' }

    offenses.each do |offense|
      assert_includes(offense[:message], 'trailing')
      refute_includes(offense[:message], 'leading')
    end
  end

  def test_when_disabled_does_not_run_validation
    disabled_config = test_config do |c|
      c.send(:set_validator_config, 'Documentation/EmptyCommentLine', 'Enabled', false)
    end

    result = Yard::Lint.run(path: fixture_path, config: disabled_config, progress: false)

    empty_comment_offenses = result.offenses.select { |o| o[:name] == 'EmptyCommentLine' }
    assert_empty(empty_comment_offenses)
  end

  def test_valid_documentation_is_not_flagged_does_not_flag_properly_formatted_docs
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    # ValidClass and valid_method have proper formatting
    # They should not appear in offenses
    valid_class_offenses = result.offenses.select do |o|
      o[:name] == 'EmptyCommentLine' &&
        o[:message].include?('ValidClass')
    end

    valid_method_offenses = result.offenses.select do |o|
      o[:name] == 'EmptyCommentLine' &&
        o[:message].include?('valid_method')
    end

    assert_empty(valid_class_offenses)
    assert_empty(valid_method_offenses)
  end
end

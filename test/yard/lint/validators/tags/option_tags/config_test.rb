# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsOptionTagsConfigTest < Minitest::Test
  def test_id_returns_the_validator_identifier
    assert_equal(:option_tags, Yard::Lint::Validators::Tags::OptionTags::Config.id)
  end

  def test_defaults_returns_default_configuration
    assert_equal(
      {
        'Enabled' => true,
        'Severity' => 'warning',
        'ParameterNames' => %w[options opts kwargs]
      },
      Yard::Lint::Validators::Tags::OptionTags::Config.defaults
    )
  end

  def test_defaults_returns_frozen_hash
    assert_predicate(Yard::Lint::Validators::Tags::OptionTags::Config.defaults, :frozen?)
  end

  def test_combines_with_returns_empty_array_for_standalone_validator
    assert_equal([], Yard::Lint::Validators::Tags::OptionTags::Config.combines_with)
  end

  def test_inheritance_inherits_from_base_config_class
    assert_equal(
      Yard::Lint::Validators::Config,
      Yard::Lint::Validators::Tags::OptionTags::Config.superclass
    )
  end
end

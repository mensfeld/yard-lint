# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsTagGroupSeparatorConfigTest < Minitest::Test
  def test_id_returns_the_validator_identifier
    assert_equal(:tag_group_separator, Yard::Lint::Validators::Tags::TagGroupSeparator::Config.id)
  end

  def test_defaults_returns_default_configuration
    assert_equal(
      {
        'Enabled' => false,
        'Severity' => 'convention',
        'TagGroups' => {
          'param' => %w[param option],
          'return' => %w[return],
          'error' => %w[raise throws],
          'example' => %w[example],
          'meta' => %w[see note todo deprecated since version api],
          'yield' => %w[yield yieldparam yieldreturn]
        },
        'RequireAfterDescription' => false
      },
      Yard::Lint::Validators::Tags::TagGroupSeparator::Config.defaults
    )
  end

  def test_defaults_returns_frozen_hash
    assert_predicate(Yard::Lint::Validators::Tags::TagGroupSeparator::Config.defaults, :frozen?)
  end

  def test_defaults_is_disabled_by_default
    assert_equal(false, Yard::Lint::Validators::Tags::TagGroupSeparator::Config.defaults['Enabled'])
  end

  def test_combines_with_returns_empty_array_for_standalone_validator
    assert_equal([], Yard::Lint::Validators::Tags::TagGroupSeparator::Config.combines_with)
  end

  def test_inheritance_inherits_from_base_config_class
    assert_equal(
      Yard::Lint::Validators::Config,
      Yard::Lint::Validators::Tags::TagGroupSeparator::Config.superclass
    )
  end
end

# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsForbiddenTagsConfigTest < Minitest::Test
  def test_class_attributes_has_id_set_to_forbidden_tags
    assert_equal(:forbidden_tags, Yard::Lint::Validators::Tags::ForbiddenTags::Config.id)
  end

  def test_class_attributes_has_defaults_configured
    assert_kind_of(Hash, Yard::Lint::Validators::Tags::ForbiddenTags::Config.defaults)
    assert_equal(false, Yard::Lint::Validators::Tags::ForbiddenTags::Config.defaults['Enabled'])
    assert_equal('convention', Yard::Lint::Validators::Tags::ForbiddenTags::Config.defaults['Severity'])
    assert_equal([], Yard::Lint::Validators::Tags::ForbiddenTags::Config.defaults['ForbiddenPatterns'])
  end

  def test_inheritance_inherits_from_validators_config
    assert_equal(
      Yard::Lint::Validators::Config,
      Yard::Lint::Validators::Tags::ForbiddenTags::Config.superclass
    )
  end
end

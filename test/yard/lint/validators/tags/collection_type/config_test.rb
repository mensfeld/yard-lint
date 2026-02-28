# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsCollectionTypeConfigTest < Minitest::Test
  def test_class_attributes_has_id_set_to_collection_type
    assert_equal(:collection_type, Yard::Lint::Validators::Tags::CollectionType::Config.id)
  end

  def test_class_attributes_has_defaults_configured
    assert_kind_of(Hash, Yard::Lint::Validators::Tags::CollectionType::Config.defaults)
    assert_equal(true, Yard::Lint::Validators::Tags::CollectionType::Config.defaults['Enabled'])
    assert_equal('convention', Yard::Lint::Validators::Tags::CollectionType::Config.defaults['Severity'])
    assert_equal(
      %w[param option return yieldreturn],
      Yard::Lint::Validators::Tags::CollectionType::Config.defaults['ValidatedTags']
    )
  end

  def test_inheritance_inherits_from_validators_config
    assert_equal(
      Yard::Lint::Validators::Config,
      Yard::Lint::Validators::Tags::CollectionType::Config.superclass
    )
  end
end

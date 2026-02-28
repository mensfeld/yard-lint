# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsMeaninglessTagConfigTest < Minitest::Test
  def test_class_attributes_has_id_set_to_meaningless_tag
    assert_equal(:meaningless_tag, Yard::Lint::Validators::Tags::MeaninglessTag::Config.id)
  end

  def test_class_attributes_has_defaults_configured
    assert_kind_of(Hash, Yard::Lint::Validators::Tags::MeaninglessTag::Config.defaults)
    assert_equal(true, Yard::Lint::Validators::Tags::MeaninglessTag::Config.defaults['Enabled'])
    assert_equal('warning', Yard::Lint::Validators::Tags::MeaninglessTag::Config.defaults['Severity'])
    assert_equal(%w[param option], Yard::Lint::Validators::Tags::MeaninglessTag::Config.defaults['CheckedTags'])
    assert_equal(
      %w[class module constant],
      Yard::Lint::Validators::Tags::MeaninglessTag::Config.defaults['InvalidObjectTypes']
    )
  end

  def test_inheritance_inherits_from_validators_config
    assert_equal(
      Yard::Lint::Validators::Config,
      Yard::Lint::Validators::Tags::MeaninglessTag::Config.superclass
    )
  end
end

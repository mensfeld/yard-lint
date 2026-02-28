# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsTagTypePositionConfigTest < Minitest::Test
  def test_has_correct_defaults
    assert_equal(:tag_type_position, Yard::Lint::Validators::Tags::TagTypePosition::Config.id)
    assert_equal('convention', Yard::Lint::Validators::Tags::TagTypePosition::Config.defaults['Severity'])
    assert_equal(%w[param option], Yard::Lint::Validators::Tags::TagTypePosition::Config.defaults['CheckedTags'])
    assert_equal(
      'type_after_name',
      Yard::Lint::Validators::Tags::TagTypePosition::Config.defaults['EnforcedStyle']
    )
  end
end

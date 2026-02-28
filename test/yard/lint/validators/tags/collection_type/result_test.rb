# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsCollectionTypeResultTest < Minitest::Test

  def test_class_attributes_has_default_severity_set_to_convention
    assert_equal('convention', Yard::Lint::Validators::Tags::CollectionType::Result.default_severity)
  end

  def test_class_attributes_has_offense_type_set_to_style
    assert_equal('style', Yard::Lint::Validators::Tags::CollectionType::Result.offense_type)
  end

  def test_class_attributes_has_offense_name_set_to_collectiontype
    assert_equal('CollectionType', Yard::Lint::Validators::Tags::CollectionType::Result.offense_name)
  end

  def test_build_message_delegates_to_messagesbuilder
    offense = {
      tag_name: 'param',
      type_string: 'Hash<Symbol, String>'
    }

    Yard::Lint::Validators::Tags::CollectionType::MessagesBuilder
      .stubs(:call)
      .with(offense)
      .returns('formatted message')

    result = Yard::Lint::Validators::Tags::CollectionType::Result.new([])
    message = result.build_message(offense)

    assert_equal('formatted message', message)
  end

  def test_inheritance_inherits_from_results_base
    assert_equal(Yard::Lint::Results::Base, Yard::Lint::Validators::Tags::CollectionType::Result.superclass)
  end
end

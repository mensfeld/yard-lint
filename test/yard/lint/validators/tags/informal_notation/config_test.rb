# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsInformalNotationConfigTest < Minitest::Test
  def test_class_attributes_has_id_set_to_informal_notation
    assert_equal(:informal_notation, Yard::Lint::Validators::Tags::InformalNotation::Config.id)
  end

  def test_class_attributes_has_defaults_configured
    assert_kind_of(Hash, Yard::Lint::Validators::Tags::InformalNotation::Config.defaults)
    assert_equal(true, Yard::Lint::Validators::Tags::InformalNotation::Config.defaults['Enabled'])
    assert_equal('warning', Yard::Lint::Validators::Tags::InformalNotation::Config.defaults['Severity'])
    assert_equal(false, Yard::Lint::Validators::Tags::InformalNotation::Config.defaults['CaseSensitive'])
    assert_equal(true, Yard::Lint::Validators::Tags::InformalNotation::Config.defaults['RequireStartOfLine'])
  end

  def test_class_attributes_has_default_patterns_configured
    patterns = Yard::Lint::Validators::Tags::InformalNotation::Config.defaults['Patterns']
    assert_kind_of(Hash, patterns)
    assert_equal('@note', patterns['Note'])
    assert_equal('@todo', patterns['Todo'])
    assert_equal('@todo', patterns['TODO'])
    assert_equal('@todo', patterns['FIXME'])
    assert_equal('@see', patterns['See'])
    assert_equal('@see', patterns['See also'])
    assert_equal('@deprecated', patterns['Warning'])
    assert_equal('@deprecated', patterns['Deprecated'])
    assert_equal('@author', patterns['Author'])
    assert_equal('@version', patterns['Version'])
    assert_equal('@since', patterns['Since'])
    assert_equal('@return', patterns['Returns'])
    assert_equal('@raise', patterns['Raises'])
    assert_equal('@example', patterns['Example'])
  end

  def test_inheritance_inherits_from_validators_config
    assert_equal(
      Yard::Lint::Validators::Config,
      Yard::Lint::Validators::Tags::InformalNotation::Config.superclass
    )
  end
end

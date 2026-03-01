# frozen_string_literal: true

require 'test_helper'


describe 'Yard::Lint::Validators::Tags::InformalNotation::Config' do
  it 'class attributes has id set to informal notation' do
    assert_equal(:informal_notation, Yard::Lint::Validators::Tags::InformalNotation::Config.id)
  end

  it 'class attributes has defaults configured' do
    assert_kind_of(Hash, Yard::Lint::Validators::Tags::InformalNotation::Config.defaults)
    assert_equal(true, Yard::Lint::Validators::Tags::InformalNotation::Config.defaults['Enabled'])
    assert_equal('warning', Yard::Lint::Validators::Tags::InformalNotation::Config.defaults['Severity'])
    assert_equal(false, Yard::Lint::Validators::Tags::InformalNotation::Config.defaults['CaseSensitive'])
    assert_equal(true, Yard::Lint::Validators::Tags::InformalNotation::Config.defaults['RequireStartOfLine'])
  end

  it 'class attributes has default patterns configured' do
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

  it 'inheritance inherits from validators config' do
    assert_equal(
      Yard::Lint::Validators::Config,
      Yard::Lint::Validators::Tags::InformalNotation::Config.superclass
    )
  end
end

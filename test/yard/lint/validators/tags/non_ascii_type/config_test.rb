# frozen_string_literal: true

require 'test_helper'


describe 'Yard::Lint::Validators::Tags::NonAsciiType::Config' do
  it 'id returns non ascii type' do
    assert_equal(:non_ascii_type, Yard::Lint::Validators::Tags::NonAsciiType::Config.id)
  end

  it 'defaults has enabled set to true' do
    assert_equal(true, Yard::Lint::Validators::Tags::NonAsciiType::Config.defaults['Enabled'])
  end

  it 'defaults has severity set to warning' do
    assert_equal('warning', Yard::Lint::Validators::Tags::NonAsciiType::Config.defaults['Severity'])
  end

  it 'defaults has validatedtags with param option return yieldreturn yieldparam' do
    expected_tags = %w[param option return yieldreturn yieldparam]
    assert_equal(expected_tags, Yard::Lint::Validators::Tags::NonAsciiType::Config.defaults['ValidatedTags'])
  end

  it 'defaults is frozen' do
    assert_predicate(Yard::Lint::Validators::Tags::NonAsciiType::Config.defaults, :frozen?)
  end

  it 'inheritance inherits from validators config' do
    assert_equal(
      Yard::Lint::Validators::Config,
      Yard::Lint::Validators::Tags::NonAsciiType::Config.superclass
    )
  end
end

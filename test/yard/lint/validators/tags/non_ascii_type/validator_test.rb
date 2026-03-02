# frozen_string_literal: true

describe 'Yard::Lint::Validators::Tags::NonAsciiType::Validator' do
  attr_reader :config, :selection, :validator, :pattern

  before do
    @config = Yard::Lint::Config.new
    @selection = ['lib/example.rb']
    @validator = Yard::Lint::Validators::Tags::NonAsciiType::Validator.new(@config, @selection)
    @pattern = Yard::Lint::Validators::Tags::NonAsciiType::Validator::NON_ASCII_PATTERN
  end

  it 'initialize inherits from base validator' do
    assert_kind_of(Yard::Lint::Validators::Base, validator)
  end

  it 'initialize stores config and selection' do
    assert_equal(@config, validator.config)
    assert_equal(@selection, validator.selection)
  end

  it 'in process returns true for in process execution' do
    assert_equal(true, Yard::Lint::Validators::Tags::NonAsciiType::Validator.in_process?)
  end

  it 'non ascii pattern matches non ascii characters' do
    ellipsis = "\u2026"
    arrow = "\u2192"
    em_dash = "\u2014"
    accented = "\u00e9"

    assert_match(pattern, ellipsis)
    assert_match(pattern, arrow)
    assert_match(pattern, em_dash)
    assert_match(pattern, accented)
  end

  it 'non ascii pattern does not match ascii characters' do
    simple_type = 'String'
    generic_type = 'Array<Integer>'
    hash_type = 'Hash{Symbol => String}'

    refute_match(pattern, simple_type)
    refute_match(pattern, generic_type)
    refute_match(pattern, hash_type)
  end
end


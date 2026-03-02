# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Validators::Tags::OptionTags' do
  it 'module structure is defined as a module' do
    assert_kind_of(Module, Yard::Lint::Validators::Tags::OptionTags)
  end

  it 'module structure has config class' do
    assert_equal(true, Yard::Lint::Validators::Tags::OptionTags.const_defined?(:Config))
  end

  it 'module structure has validator class' do
    assert_equal(true, Yard::Lint::Validators::Tags::OptionTags.const_defined?(:Validator))
  end

  it 'module structure has parser class' do
    assert_equal(true, Yard::Lint::Validators::Tags::OptionTags.const_defined?(:Parser))
  end

  it 'module structure has result class' do
    assert_equal(true, Yard::Lint::Validators::Tags::OptionTags.const_defined?(:Result))
  end
end


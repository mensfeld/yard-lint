# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Version' do
  it 'version has a version number' do
    refute_nil(Yard::Lint::VERSION)
  end

  it 'version version is a string' do
    assert_kind_of(String, Yard::Lint::VERSION)
  end

  it 'version version follows semantic versioning format' do
    assert_match(/\A\d+\.\d+\.\d+/, Yard::Lint::VERSION)
  end

  it 'version version is frozen' do
    assert_predicate(Yard::Lint::VERSION, :frozen?)
  end
end


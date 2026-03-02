# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Validators::Warnings::UnknownParameterName::Result' do
  attr_reader :config, :parsed_data, :result

  before do
    @config = Yard::Lint::Config.new
    @parsed_data = []
    @result = Yard::Lint::Validators::Warnings::UnknownParameterName::Result.new(parsed_data, config)
  end

  it 'initialize inherits from base result' do
    assert_kind_of(Yard::Lint::Results::Base, result)
  end

  it 'initialize stores config' do
    assert_equal(config, result.instance_variable_get(:@config))
  end

  it 'offenses returns an array' do
    assert_kind_of(Array, result.offenses)
  end

  it 'offenses returns empty array for empty parsed data' do
    assert_equal([], result.offenses)
  end
end


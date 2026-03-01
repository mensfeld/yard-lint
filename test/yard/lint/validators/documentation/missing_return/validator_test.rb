# frozen_string_literal: true

require 'test_helper'


describe 'Yard::Lint::Validators::Documentation::MissingReturn::Validator' do
  attr_reader :config, :selection, :validator


  before do
    @config = Yard::Lint::Config.new
    @selection = ['lib/example.rb']
    @validator = Yard::Lint::Validators::Documentation::MissingReturn::Validator.new(config, selection)
  end

  it 'initialize inherits from base validator' do
    assert_kind_of(Yard::Lint::Validators::Base, validator)
  end

  it 'initialize stores config and selection' do
  end

  it 'in process returns true for in process execution' do
    assert_equal(true, Yard::Lint::Validators::Documentation::MissingReturn::Validator.in_process?)
  end
end


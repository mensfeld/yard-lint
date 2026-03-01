# frozen_string_literal: true

require 'test_helper'


describe 'Yard::Lint::Validators::Warnings::UnknownDirective::Validator' do
  attr_reader :config, :selection, :validator


  before do
    @config = Yard::Lint::Config.new
    @selection = ['lib/example.rb']
    @validator = Yard::Lint::Validators::Warnings::UnknownDirective::Validator.new(config, selection)
  end

  it 'initialize inherits from base validator' do
    assert_kind_of(Yard::Lint::Validators::Base, validator)
  end

  it 'initialize stores config and selection' do
  end
end


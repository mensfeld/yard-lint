# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Validators::Tags::ExampleStyle' do
  it 'module structure is defined as a module' do
    assert_kind_of(Module, Yard::Lint::Validators::Tags::ExampleStyle)
  end

  it 'module structure has config class' do
    assert_equal(true, Yard::Lint::Validators::Tags::ExampleStyle.const_defined?(:Config))
  end

  it 'module structure has validator class' do
    assert_equal(true, Yard::Lint::Validators::Tags::ExampleStyle.const_defined?(:Validator))
  end

  it 'module structure has parser class' do
    assert_equal(true, Yard::Lint::Validators::Tags::ExampleStyle.const_defined?(:Parser))
  end

  it 'module structure has result class' do
    assert_equal(true, Yard::Lint::Validators::Tags::ExampleStyle.const_defined?(:Result))
  end

  it 'module structure has messagesbuilder class' do
    assert_equal(true, Yard::Lint::Validators::Tags::ExampleStyle.const_defined?(:MessagesBuilder))
  end

  it 'module structure has linterdetector class' do
    assert_equal(true, Yard::Lint::Validators::Tags::ExampleStyle.const_defined?(:LinterDetector))
  end

  it 'module structure has rubocoprunner class' do
    assert_equal(true, Yard::Lint::Validators::Tags::ExampleStyle.const_defined?(:RubocopRunner))
  end
end


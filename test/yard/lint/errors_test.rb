# frozen_string_literal: true

require 'test_helper'


describe 'Yard::Lint::Errors' do
  it 'baseerror is a standarderror' do
    assert_kind_of(StandardError, Yard::Lint::Errors::BaseError.new)
  end

  it 'baseerror accepts a custom message' do
    error = Yard::Lint::Errors::BaseError.new('custom message')
    assert_equal('custom message', error.message)
  end

  it 'configfilenotfounderror inherits from baseerror' do
    assert_kind_of(Yard::Lint::Errors::BaseError, Yard::Lint::Errors::ConfigFileNotFoundError.new)
  end

  it 'configfilenotfounderror can be raised with a message' do
    error = assert_raises(Yard::Lint::Errors::ConfigFileNotFoundError) do
      raise Yard::Lint::Errors::ConfigFileNotFoundError, 'File not found'
      end
    assert_equal('File not found', error.message)
  end

  it 'circulardependencyerror inherits from baseerror' do
    assert_kind_of(Yard::Lint::Errors::BaseError, Yard::Lint::Errors::CircularDependencyError.new)
  end

  it 'circulardependencyerror can be raised with a message' do
    error = assert_raises(Yard::Lint::Errors::CircularDependencyError) do
      raise Yard::Lint::Errors::CircularDependencyError, 'Circular dependency detected'
      end
    assert_equal('Circular dependency detected', error.message)
  end
end

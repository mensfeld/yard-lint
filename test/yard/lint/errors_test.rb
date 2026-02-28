# frozen_string_literal: true

require 'test_helper'

class YardLintErrorsTest < Minitest::Test
  def test_baseerror_is_a_standarderror
    assert_kind_of(StandardError, Yard::Lint::Errors::BaseError.new)
  end

  def test_baseerror_accepts_a_custom_message
    error = Yard::Lint::Errors::BaseError.new('custom message')
    assert_equal('custom message', error.message)
  end

  def test_configfilenotfounderror_inherits_from_baseerror
    assert_kind_of(Yard::Lint::Errors::BaseError, Yard::Lint::Errors::ConfigFileNotFoundError.new)
  end

  def test_configfilenotfounderror_can_be_raised_with_a_message
    error = assert_raises(Yard::Lint::Errors::ConfigFileNotFoundError) do
      raise Yard::Lint::Errors::ConfigFileNotFoundError, 'File not found'
      end
    assert_equal('File not found', error.message)
  end

  def test_circulardependencyerror_inherits_from_baseerror
    assert_kind_of(Yard::Lint::Errors::BaseError, Yard::Lint::Errors::CircularDependencyError.new)
  end

  def test_circulardependencyerror_can_be_raised_with_a_message
    error = assert_raises(Yard::Lint::Errors::CircularDependencyError) do
      raise Yard::Lint::Errors::CircularDependencyError, 'Circular dependency detected'
      end
    assert_equal('Circular dependency detected', error.message)
  end
end

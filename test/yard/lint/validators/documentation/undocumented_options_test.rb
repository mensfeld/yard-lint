# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Validators::Documentation::UndocumentedOptions' do
  it 'is a module' do
  assert_kind_of(Module, Yard::Lint::Validators::Documentation::UndocumentedOptions)
  end

  it 'has required sub modules and classes' do
  assert_equal(true, Yard::Lint::Validators::Documentation::UndocumentedOptions.const_defined?(:Config))
  assert_equal(true, Yard::Lint::Validators::Documentation::UndocumentedOptions.const_defined?(:Validator))
  assert_equal(true, Yard::Lint::Validators::Documentation::UndocumentedOptions.const_defined?(:Parser))
  assert_equal(true, Yard::Lint::Validators::Documentation::UndocumentedOptions.const_defined?(:Result))
  end
end


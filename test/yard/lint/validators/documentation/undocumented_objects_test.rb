# frozen_string_literal: true

require 'test_helper'


describe 'Yard::Lint::Validators::Documentation::UndocumentedObjects' do
  it 'module structure is defined as a module' do
    assert_kind_of(Module, Yard::Lint::Validators::Documentation::UndocumentedObjects)
  end

  it 'module structure has config class' do
    assert_equal(true, Yard::Lint::Validators::Documentation::UndocumentedObjects.const_defined?(:Config))
  end

  it 'module structure has validator class' do
    assert_equal(true, Yard::Lint::Validators::Documentation::UndocumentedObjects.const_defined?(:Validator))
  end

  it 'module structure has parser class' do
    assert_equal(true, Yard::Lint::Validators::Documentation::UndocumentedObjects.const_defined?(:Parser))
  end

  it 'module structure has result class' do
    assert_equal(true, Yard::Lint::Validators::Documentation::UndocumentedObjects.const_defined?(:Result))
  end
end


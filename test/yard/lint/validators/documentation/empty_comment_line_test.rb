# frozen_string_literal: true

describe 'Yard::Lint::Validators::Documentation::EmptyCommentLine' do
  it 'is a module' do
  assert_kind_of(Module, Yard::Lint::Validators::Documentation::EmptyCommentLine)
  end

  it 'has required sub modules and classes' do
  assert_equal(true, Yard::Lint::Validators::Documentation::EmptyCommentLine.const_defined?(:Config))
  assert_equal(true, Yard::Lint::Validators::Documentation::EmptyCommentLine.const_defined?(:Validator))
  assert_equal(true, Yard::Lint::Validators::Documentation::EmptyCommentLine.const_defined?(:Parser))
  assert_equal(true, Yard::Lint::Validators::Documentation::EmptyCommentLine.const_defined?(:Result))
  assert_equal(true, Yard::Lint::Validators::Documentation::EmptyCommentLine.const_defined?(:MessagesBuilder))
  end
end


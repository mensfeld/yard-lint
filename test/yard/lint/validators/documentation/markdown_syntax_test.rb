# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Validators::Documentation::MarkdownSyntax' do
  it 'is a module' do
  assert_kind_of(Module, Yard::Lint::Validators::Documentation::MarkdownSyntax)
  end

  it 'has required sub modules and classes' do
  assert_equal(true, Yard::Lint::Validators::Documentation::MarkdownSyntax.const_defined?(:Config))
  assert_equal(true, Yard::Lint::Validators::Documentation::MarkdownSyntax.const_defined?(:Validator))
  assert_equal(true, Yard::Lint::Validators::Documentation::MarkdownSyntax.const_defined?(:Parser))
  assert_equal(true, Yard::Lint::Validators::Documentation::MarkdownSyntax.const_defined?(:Result))
  assert_equal(true, Yard::Lint::Validators::Documentation::MarkdownSyntax.const_defined?(:MessagesBuilder))
  end
end


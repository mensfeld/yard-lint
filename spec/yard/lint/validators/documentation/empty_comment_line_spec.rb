# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Documentation::EmptyCommentLine do
  it 'is a module' do
    expect(described_class).to be_a(Module)
  end

  it 'has required sub-modules and classes' do
    expect(described_class.const_defined?(:Config)).to be true
    expect(described_class.const_defined?(:Validator)).to be true
    expect(described_class.const_defined?(:Parser)).to be true
    expect(described_class.const_defined?(:Result)).to be true
    expect(described_class.const_defined?(:MessagesBuilder)).to be true
  end
end

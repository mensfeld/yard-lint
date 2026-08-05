# frozen_string_literal: true

describe "Yard::Lint::Validators::Tags::TagSeparator" do
  it "module structure is defined as a module" do
    assert_kind_of(Module, Yard::Lint::Validators::Tags::TagSeparator)
  end

  it "module structure has config class" do
    assert(Yard::Lint::Validators::Tags::TagSeparator.const_defined?(:Config))
  end

  it "module structure has validator class" do
    assert(Yard::Lint::Validators::Tags::TagSeparator.const_defined?(:Validator))
  end

  it "module structure has parser class" do
    assert(Yard::Lint::Validators::Tags::TagSeparator.const_defined?(:Parser))
  end

  it "module structure has result class" do
    assert(Yard::Lint::Validators::Tags::TagSeparator.const_defined?(:Result))
  end
end

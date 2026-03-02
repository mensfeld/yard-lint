# frozen_string_literal: true

describe 'Yard::Lint::Validators::Tags::ForbiddenTags::Config' do
  it 'class attributes has id set to forbidden tags' do
    assert_equal(:forbidden_tags, Yard::Lint::Validators::Tags::ForbiddenTags::Config.id)
  end

  it 'class attributes has defaults configured' do
    assert_kind_of(Hash, Yard::Lint::Validators::Tags::ForbiddenTags::Config.defaults)
    assert_equal(false, Yard::Lint::Validators::Tags::ForbiddenTags::Config.defaults['Enabled'])
    assert_equal('convention', Yard::Lint::Validators::Tags::ForbiddenTags::Config.defaults['Severity'])
    assert_equal([], Yard::Lint::Validators::Tags::ForbiddenTags::Config.defaults['ForbiddenPatterns'])
  end

  it 'inheritance inherits from validators config' do
    assert_equal(
      Yard::Lint::Validators::Config,
      Yard::Lint::Validators::Tags::ForbiddenTags::Config.superclass
    )
  end
end


# frozen_string_literal: true

describe 'Yard::Lint::Validators::Tags::CollectionType::Config' do
  it 'class attributes has id set to collection type' do
    assert_equal(:collection_type, Yard::Lint::Validators::Tags::CollectionType::Config.id)
  end

  it 'class attributes has defaults configured' do
    assert_kind_of(Hash, Yard::Lint::Validators::Tags::CollectionType::Config.defaults)
    assert_equal(true, Yard::Lint::Validators::Tags::CollectionType::Config.defaults['Enabled'])
    assert_equal('convention', Yard::Lint::Validators::Tags::CollectionType::Config.defaults['Severity'])
    assert_equal(
      %w[param option return yieldreturn],
      Yard::Lint::Validators::Tags::CollectionType::Config.defaults['ValidatedTags']
    )
  end

  it 'inheritance inherits from validators config' do
    assert_equal(
      Yard::Lint::Validators::Config,
      Yard::Lint::Validators::Tags::CollectionType::Config.superclass
    )
  end
end


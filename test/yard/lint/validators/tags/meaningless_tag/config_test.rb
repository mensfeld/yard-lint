# frozen_string_literal: true

describe 'Yard::Lint::Validators::Tags::MeaninglessTag::Config' do
  it 'class attributes has id set to meaningless tag' do
    assert_equal(:meaningless_tag, Yard::Lint::Validators::Tags::MeaninglessTag::Config.id)
  end

  it 'class attributes has defaults configured' do
    assert_kind_of(Hash, Yard::Lint::Validators::Tags::MeaninglessTag::Config.defaults)
    assert_equal(true, Yard::Lint::Validators::Tags::MeaninglessTag::Config.defaults['Enabled'])
    assert_equal('warning', Yard::Lint::Validators::Tags::MeaninglessTag::Config.defaults['Severity'])
    assert_equal(%w[param option], Yard::Lint::Validators::Tags::MeaninglessTag::Config.defaults['CheckedTags'])
    assert_equal(
      %w[class module constant],
      Yard::Lint::Validators::Tags::MeaninglessTag::Config.defaults['InvalidObjectTypes']
    )
  end

  it 'inheritance inherits from validators config' do
    assert_equal(
      Yard::Lint::Validators::Config,
      Yard::Lint::Validators::Tags::MeaninglessTag::Config.superclass
    )
  end
end


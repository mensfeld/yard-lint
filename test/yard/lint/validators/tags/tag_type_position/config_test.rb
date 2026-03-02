# frozen_string_literal: true

describe 'Yard::Lint::Validators::Tags::TagTypePosition::Config' do
  it 'has correct defaults' do
    assert_equal(:tag_type_position, Yard::Lint::Validators::Tags::TagTypePosition::Config.id)
    assert_equal('convention', Yard::Lint::Validators::Tags::TagTypePosition::Config.defaults['Severity'])
    assert_equal(%w[param option], Yard::Lint::Validators::Tags::TagTypePosition::Config.defaults['CheckedTags'])
    assert_equal(
      'type_after_name',
      Yard::Lint::Validators::Tags::TagTypePosition::Config.defaults['EnforcedStyle']
    )
  end
end


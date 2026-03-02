# frozen_string_literal: true

describe 'Yard::Lint::Validators::Tags::ApiTags::Config' do
  it 'id returns the validator identifier' do
    assert_equal(:api_tags, Yard::Lint::Validators::Tags::ApiTags::Config.id)
  end

  it 'defaults returns default configuration' do
    assert_equal(
      {
        'Enabled' => false,
        'Severity' => 'warning',
        'AllowedApis' => %w[public private internal]
      },
      Yard::Lint::Validators::Tags::ApiTags::Config.defaults
    )
  end

  it 'defaults returns frozen hash' do
    assert_predicate(Yard::Lint::Validators::Tags::ApiTags::Config.defaults, :frozen?)
  end

  it 'combines with returns empty array for standalone validator' do
    assert_equal([], Yard::Lint::Validators::Tags::ApiTags::Config.combines_with)
  end

  it 'inheritance inherits from base config class' do
    assert_equal(
      Yard::Lint::Validators::Config,
      Yard::Lint::Validators::Tags::ApiTags::Config.superclass
    )
  end
end


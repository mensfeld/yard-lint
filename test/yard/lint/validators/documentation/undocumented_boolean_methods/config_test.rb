# frozen_string_literal: true

describe 'Yard::Lint::Validators::Documentation::UndocumentedBooleanMethods::Config' do
  it 'id returns the validator identifier' do
    assert_equal(
      :undocumented_boolean_methods,
      Yard::Lint::Validators::Documentation::UndocumentedBooleanMethods::Config.id
    )
  end

  it 'defaults returns default configuration' do
    assert_equal(
      {
        'Enabled' => true,
        'Severity' => 'warning'
      },
      Yard::Lint::Validators::Documentation::UndocumentedBooleanMethods::Config.defaults
    )
  end

  it 'defaults returns frozen hash' do
    assert_predicate(Yard::Lint::Validators::Documentation::UndocumentedBooleanMethods::Config.defaults, :frozen?)
  end

  it 'combines with returns empty array for standalone validator' do
    assert_equal([], Yard::Lint::Validators::Documentation::UndocumentedBooleanMethods::Config.combines_with)
  end

  it 'inheritance inherits from base config class' do
    assert_equal(
      Yard::Lint::Validators::Config,
      Yard::Lint::Validators::Documentation::UndocumentedBooleanMethods::Config.superclass
    )
  end
end


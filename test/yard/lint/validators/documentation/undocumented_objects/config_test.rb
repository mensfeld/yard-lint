# frozen_string_literal: true

describe 'Yard::Lint::Validators::Documentation::UndocumentedObjects::Config' do
  it 'id returns the validator identifier' do
    assert_equal(
      :undocumented_objects,
      Yard::Lint::Validators::Documentation::UndocumentedObjects::Config.id
    )
  end

  it 'defaults returns default configuration' do
    assert_equal(
      {
        'Enabled' => true,
        'Severity' => 'warning',
        'ExcludedMethods' => ['initialize/0']
      },
      Yard::Lint::Validators::Documentation::UndocumentedObjects::Config.defaults
    )
  end

  it 'defaults returns frozen hash' do
    assert_predicate(Yard::Lint::Validators::Documentation::UndocumentedObjects::Config.defaults, :frozen?)
  end

  it 'combines with combines with undocumented boolean methods validator' do
    assert_equal(
      ['Documentation/UndocumentedBooleanMethods'],
      Yard::Lint::Validators::Documentation::UndocumentedObjects::Config.combines_with
    )
  end

  it 'combines with returns frozen array' do
    assert_predicate(Yard::Lint::Validators::Documentation::UndocumentedObjects::Config.combines_with, :frozen?)
  end

  it 'inheritance inherits from base config class' do
    assert_equal(
      Yard::Lint::Validators::Config,
      Yard::Lint::Validators::Documentation::UndocumentedObjects::Config.superclass
    )
  end
end


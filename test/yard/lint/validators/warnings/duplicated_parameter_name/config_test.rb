# frozen_string_literal: true

require 'test_helper'


describe 'Yard::Lint::Validators::Warnings::DuplicatedParameterName::Config' do
  it 'id returns the validator identifier' do
    assert_equal(
      :duplicated_parameter_name,
      Yard::Lint::Validators::Warnings::DuplicatedParameterName::Config.id
    )
  end

  it 'defaults returns default configuration' do
    assert_equal(
      {
        'Enabled' => true,
        'Severity' => 'error'
      },
      Yard::Lint::Validators::Warnings::DuplicatedParameterName::Config.defaults
    )
  end

  it 'defaults returns frozen hash' do
    assert_predicate(Yard::Lint::Validators::Warnings::DuplicatedParameterName::Config.defaults, :frozen?)
  end

  it 'combines with returns empty array for standalone validator' do
    assert_equal([], Yard::Lint::Validators::Warnings::DuplicatedParameterName::Config.combines_with)
  end

  it 'inheritance inherits from base config class' do
    assert_equal(
      Yard::Lint::Validators::Config,
      Yard::Lint::Validators::Warnings::DuplicatedParameterName::Config.superclass
    )
  end
end

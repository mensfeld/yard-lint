# frozen_string_literal: true

require 'test_helper'


describe 'Yard::Lint::Validators::Tags::TagGroupSeparator::Config' do
  it 'id returns the validator identifier' do
    assert_equal(:tag_group_separator, Yard::Lint::Validators::Tags::TagGroupSeparator::Config.id)
  end

  it 'defaults returns default configuration' do
    assert_equal(
      {
        'Enabled' => false,
        'Severity' => 'convention',
        'TagGroups' => {
          'param' => %w[param option],
          'return' => %w[return],
          'error' => %w[raise throws],
          'example' => %w[example],
          'meta' => %w[see note todo deprecated since version api],
          'yield' => %w[yield yieldparam yieldreturn]
        },
        'RequireAfterDescription' => false
      },
      Yard::Lint::Validators::Tags::TagGroupSeparator::Config.defaults
    )
  end

  it 'defaults returns frozen hash' do
    assert_predicate(Yard::Lint::Validators::Tags::TagGroupSeparator::Config.defaults, :frozen?)
  end

  it 'defaults is disabled by default' do
    assert_equal(false, Yard::Lint::Validators::Tags::TagGroupSeparator::Config.defaults['Enabled'])
  end

  it 'combines with returns empty array for standalone validator' do
    assert_equal([], Yard::Lint::Validators::Tags::TagGroupSeparator::Config.combines_with)
  end

  it 'inheritance inherits from base config class' do
    assert_equal(
      Yard::Lint::Validators::Config,
      Yard::Lint::Validators::Tags::TagGroupSeparator::Config.superclass
    )
  end
end

# frozen_string_literal: true

RSpec.describe Yard::Lint::Validators::Tags::TagTypePosition::Config do
  it 'has correct defaults' do
    expect(described_class.id).to eq(:tag_type_position)
    expect(described_class.defaults['Severity']).to eq('convention')
    expect(described_class.defaults['CheckedTags']).to eq(%w[param option])
    expect(described_class.defaults['EnforcedStyle']).to eq('type_after_name')
  end
end

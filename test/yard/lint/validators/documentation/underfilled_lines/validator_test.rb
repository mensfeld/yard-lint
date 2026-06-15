# frozen_string_literal: true

describe 'Yard::Lint::Validators::Documentation::UnderfilledLines::Validator' do
  attr_reader :config, :selection, :validator

  before do
    @config = Yard::Lint::Config.new
    @selection = ['lib/example.rb']
    @validator = Yard::Lint::Validators::Documentation::UnderfilledLines::Validator.new(config, selection)
  end

  it 'initialize inherits from base validator' do
    assert_kind_of(Yard::Lint::Validators::Base, validator)
  end

  it 'in process returns true for in process execution' do
    assert_equal(true, Yard::Lint::Validators::Documentation::UnderfilledLines::Validator.in_process?)
  end

  it 'in process visibility includes all objects' do
    assert_equal(:all, Yard::Lint::Validators::Documentation::UnderfilledLines::Validator.in_process_visibility)
  end
end

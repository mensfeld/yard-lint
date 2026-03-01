# frozen_string_literal: true

require 'test_helper'


describe 'Macro' do
  attr_reader :fixtures_path, :config


  before do
    @fixtures_path = [
      File.expand_path('fixtures/macro_a.rb', __dir__),
      File.expand_path('fixtures/macro_b.rb', __dir__)
    ]
    @config = test_config
  end

  it 'macro attachment and expansion correctly attaches and expands macros across files' do
    result = Yard::Lint.run(path: fixtures_path, config: config, progress: false)

    assert_operator(result.count, :==, 0)
  end

  it 'macro attachment and expansion correctly attaches and expands macros across files reversed order' do
    result = Yard::Lint.run(path: fixtures_path.reverse, config: config, progress: false)

    assert_operator(result.count, :==, 0)
  end
end

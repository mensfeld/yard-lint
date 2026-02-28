# frozen_string_literal: true

require 'test_helper'

class MacroIntegrationTest < Minitest::Test
  attr_reader :config, :fixtures_path

  def setup
    @fixtures_path = [
      File.expand_path('fixtures/macro_a.rb', __dir__),
      File.expand_path('fixtures/macro_b.rb', __dir__)
    ]
    @config = test_config
  end

  def test_macro_attachment_and_expansion_correctly_attaches_and_expands_macros_across_files
    result = Yard::Lint.run(path: fixtures_path, config: config, progress: false)

    assert_operator(result.count, :==, 0)
  end

  def test_macro_attachment_and_expansion_correctly_attaches_and_expands_macros_across_files_reversed_order
    result = Yard::Lint.run(path: fixtures_path.reverse, config: config, progress: false)

    assert_operator(result.count, :==, 0)
  end
end

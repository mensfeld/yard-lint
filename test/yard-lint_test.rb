# frozen_string_literal: true

  require 'yard-lint'
require 'test_helper'

class YardLintTest < Minitest::Test

  def test_gem_loading_loads_without_errors
  end

  def test_gem_loading_defines_yard_module
  end

  def test_gem_loading_defines_yard_lint_module
  end

  def test_zeitwerk_loader_auto_loads_validators
  end

  def test_zeitwerk_loader_auto_loads_results
  end

  def test_zeitwerk_loader_auto_loads_config
  end

  def test_manual_requires_loads_base_config_class
  end

  def test_manual_requires_loads_main_yard_lint_module
    assert_respond_to(Yard::Lint, :run)
  end
end


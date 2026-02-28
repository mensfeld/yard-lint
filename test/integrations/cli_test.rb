# frozen_string_literal: true

require 'English'
require 'test_helper'

class CliIntegrationTestsTest < Minitest::Test

  def setup
    @bin_path = File.expand_path('../../bin/yard-lint', __dir__)
  end

  def test_version_flag_displays_the_version_number
    output = `#{@bin_path} --version 2>&1`
    assert_equal(true, $CHILD_STATUS.success?)
    assert_match(/yard-lint \d+\.\d+\.\d+/, output)
    assert_equal("yard-lint #{Yard::Lint::VERSION}", output.strip)
  end

  def test_version_flag_exits_successfully
    `#{@bin_path} --version 2>&1`
    assert_equal(0, $CHILD_STATUS.exitstatus)
  end

  def test_version_flag_v_flag_displays_the_version_number
    output = `#{@bin_path} -v 2>&1`
    assert_equal(true, $CHILD_STATUS.success?)
    assert_match(/yard-lint \d+\.\d+\.\d+/, output)
    assert_equal("yard-lint #{Yard::Lint::VERSION}", output.strip)
  end

  def test_v_flag_exits_successfully
    `#{@bin_path} -v 2>&1`
    assert_equal(0, $CHILD_STATUS.exitstatus)
  end
end

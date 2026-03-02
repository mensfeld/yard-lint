# frozen_string_literal: true

require 'test_helper'

require 'English'

describe 'Cli' do
  attr_reader :bin_path

  before do
    @bin_path = File.expand_path('../../bin/yard-lint', __dir__)
  end

  it 'version flag displays the version number' do
    output = `#{@bin_path} --version 2>&1`
    assert_equal(true, $CHILD_STATUS.success?)
    assert_match(/yard-lint \d+\.\d+\.\d+/, output)
    assert_equal("yard-lint #{Yard::Lint::VERSION}", output.strip)
  end

  it 'version flag exits successfully' do
    `#{@bin_path} --version 2>&1`
    assert_equal(0, $CHILD_STATUS.exitstatus)
  end

  it 'version flag v flag displays the version number' do
    output = `#{@bin_path} -v 2>&1`
    assert_equal(true, $CHILD_STATUS.success?)
    assert_match(/yard-lint \d+\.\d+\.\d+/, output)
    assert_equal("yard-lint #{Yard::Lint::VERSION}", output.strip)
  end

  it 'v flag exits successfully' do
    `#{@bin_path} -v 2>&1`
    assert_equal(0, $CHILD_STATUS.exitstatus)
  end
end


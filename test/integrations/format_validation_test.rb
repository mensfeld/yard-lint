# frozen_string_literal: true

require 'English'

# Proves that an unknown --format value is rejected before the lint runs,
# not only after the (potentially long) run completes. Combined with a
# nonexistent path, the format error must win - demonstrating it is checked
# up front.
describe 'Format validation' do
  attr_reader :bin_path

  before do
    @bin_path = File.expand_path('../../bin/yard-lint', __dir__)
  end

  it 'rejects an unknown format before running' do
    output = `#{bin_path} --format xml /no/such/path 2>&1`

    assert_equal(1, $CHILD_STATUS.exitstatus)
    assert_match(/Unknown format 'xml'/, output)
  end
end

# frozen_string_literal: true

require 'English'

# Proves that --min-coverage outside 0-100 is rejected like MinCoverage in the
# config, instead of always failing (above 100) or always passing (below 0).
describe 'Min coverage range' do
  attr_reader :bin_path

  before do
    @bin_path = File.expand_path('../../bin/yard-lint', __dir__)
    @dir = Dir.mktmpdir
    File.write(File.join(@dir, 'foo.rb'), <<~RUBY)
      # frozen_string_literal: true

      # Documented class
      class Foo
        # Documented method
        # @return [Integer] one
        def bar
          1
        end
      end
    RUBY
  end

  after do
    FileUtils.rm_rf(@dir)
  end

  %w[120 -5 100.1].each do |value|
    it "rejects --min-coverage #{value}" do
      output = `#{bin_path} --min-coverage #{value} #{@dir} 2>&1`

      assert_equal(1, $CHILD_STATUS.exitstatus)
      assert_match(/Invalid --min-coverage: '#{Regexp.escape(Float(value).to_s)}'/, output)
      assert_match(/Must be a number between 0 and 100/, output)
    end
  end

  %w[0 100].each do |value|
    it "accepts --min-coverage #{value}" do
      output = Dir.chdir(@dir) { `#{bin_path} --min-coverage #{value} foo.rb 2>&1` }

      assert_equal(0, $CHILD_STATUS.exitstatus, output)
      refute_match(/Invalid --min-coverage/, output)
    end
  end
end

# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

# `def CONST.name` leaves YARD with an unresolved (Proxy) namespace for the
# method. The tag separator validators look up module_function twins in the
# method's namespace and must not crash on it.
describe 'Tag separators on a singleton method defined on a constant' do
  attr_reader :dir

  # @return [String] constant assigned before the singleton method
  def any_source
    <<~RUBY
      # App
      module ConstantSingletonApp
        # Extensions
        module Ext
          ANY = Object.new
          def ANY.==(_)
            true
          end
        end
      end
    RUBY
  end

  # The constant is assigned after the `def`, so YARD resolves the namespace
  # to a ConstantObject rather than leaving a Proxy
  # @return [String] constant assigned after the singleton methods
  def later_source
    <<~RUBY
      # App
      module ConstantSingletonLaterApp
        # Ext
        module Ext
          def LATER.==(_)
            true
          end

          # Same, documented
          def LATER.eql?(_)
            true
          end

          # Later
          LATER = Object.new
        end
      end
    RUBY
  end

  before { @dir = Dir.mktmpdir }
  after { FileUtils.rm_rf(dir) }

  # @param validator [String] validator to enable
  # @param source [String] Ruby source to lint
  # @return [Yard::Lint::Result] result of linting the source
  def run_with(validator, source = any_source)
    path = File.join(dir, 'example.rb')
    File.write(path, source)

    config = test_config { |c| c.set_validator_config(validator, 'Enabled', true) }
    Yard::Lint.run(path: path, config: config, progress: false)
  end

  it 'does not crash Tags/TagSeparator' do
    offenses = run_with('Tags/TagSeparator').offenses

    assert_empty(offenses.select { |offense| offense[:validator] == 'Tags/TagSeparator' })
  end

  it 'does not crash Tags/TagGroupSeparator' do
    offenses = run_with('Tags/TagGroupSeparator').offenses

    assert_empty(offenses.select { |offense| offense[:validator] == 'Tags/TagGroupSeparator' })
  end

  %w[Tags/TagSeparator Tags/TagGroupSeparator].each do |validator|
    it "does not crash #{validator} when the constant is assigned after the def" do
      offenses = run_with(validator, later_source).offenses

      assert_empty(offenses.select { |offense| offense[:validator] == validator })
    end
  end
end

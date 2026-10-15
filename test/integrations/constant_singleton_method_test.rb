# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

# `def CONST.name` leaves YARD with an unresolved (Proxy) namespace for the
# method. The tag separator validators look up module_function twins in the
# method's namespace and must not crash on it.
describe 'Tag separators on a singleton method defined on a constant' do
  attr_reader :dir

  before { @dir = Dir.mktmpdir }
  after { FileUtils.rm_rf(dir) }

  # @param validator [String] validator to enable
  # @return [Yard::Lint::Result] result of linting the source
  def run_with(validator)
    path = File.join(dir, 'example.rb')
    File.write(path, <<~RUBY)
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
end

# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

# Proves that Tags/TagSeparator and Tags/TagGroupSeparator do not crash on a
# singleton method defined on a constant (`def CONST.name`). Such a method has
# no namespace YARD can list children of: a Proxy when the constant is assigned
# before the `def`, a ConstantObject when it is assigned after it. Both
# validators look up module_function twins in the method's namespace, so each
# case is covered here.
%w[Tags/TagSeparator Tags/TagGroupSeparator].each do |validator|
  describe "#{validator} with a singleton method defined on a constant" do
    attr_reader :dir

    before { @dir = Dir.mktmpdir }
    after { FileUtils.rm_rf(dir) }

    # define_method so the block closes over validator, which a def cannot
    define_method(:offenses_for) do |source|
      path = File.join(dir, 'example.rb')
      File.write(path, source)

      config = test_config { |c| c.set_validator_config(validator, 'Enabled', true) }
      result = Yard::Lint.run(path: path, config: config, progress: false)
      result.offenses.select { |offense| offense[:validator] == validator }
    end

    it 'does not crash when the constant is assigned before the def' do
      assert_empty(offenses_for(<<~RUBY))
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

    it 'does not crash when the constant is assigned after the def' do
      assert_empty(offenses_for(<<~RUBY))
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
  end
end

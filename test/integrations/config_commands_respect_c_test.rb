# frozen_string_literal: true

require 'English'
require 'tmpdir'

# Proves that --update and --auto-gen-config honor the -c CONFIG path instead
# of always targeting ./.yard-lint.yml.
describe 'config commands respect -c' do
  attr_reader :bin_path

  before do
    @bin_path = File.expand_path('../../bin/yard-lint', __dir__)
  end

  it 'updates the -c config file, not ./.yard-lint.yml' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.write('custom.yml', "AllValidators:\n  Exclude: []\n")
        output = `#{bin_path} --update -c custom.yml 2>&1`

        assert_equal(0, $CHILD_STATUS.exitstatus, output)
        refute(File.exist?('.yard-lint.yml'), 'should not have created ./.yard-lint.yml')
        # custom.yml should now contain validator sections added by --update
        assert_match(%r{Documentation/}, File.read('custom.yml'))
      end
    end
  end

  it 'links the todo into the -c config file' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.write('custom.yml', "AllValidators:\n  Exclude: []\n")
        File.write('thing.rb', "class Thing\n  def m(a); a; end\nend\n")
        `#{bin_path} --auto-gen-config -c custom.yml 2>&1`

        assert(File.exist?('.yard-lint-todo.yml'), 'todo file should be generated')
        assert_match(/inherit_from/, File.read('custom.yml'), 'custom config should inherit the todo')
        refute(File.exist?('.yard-lint.yml'), 'should not have created a stray ./.yard-lint.yml')
      end
    end
  end
end

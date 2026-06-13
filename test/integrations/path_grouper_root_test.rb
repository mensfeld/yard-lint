# frozen_string_literal: true

require 'tmpdir'

# Proves that PathGrouper emits a usable exclude pattern for root-level files.
# File.dirname of a root file is ".", and the old "./**/*" pattern matches
# nothing under File.fnmatch (FNM_PATHNAME), so a generated todo file failed
# to exclude the very files it grouped - yard-lint kept failing right after
# --auto-gen-config.
describe 'PathGrouper root-level grouping' do
  it 'emits a fnmatch-able pattern for grouped root-level files' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        files = (1..20).map { |i| "file#{i}.rb" }
        files.each { |f| File.write(f, "# doc\nclass C#{File.basename(f, '.rb')}; end\n") }

        result = Yard::Lint::PathGrouper.group(files, limit: 15)

        # It should group into a single pattern that actually matches the files
        flags = File::FNM_PATHNAME | File::FNM_EXTGLOB
        assert(
          result.any? { |pattern| File.fnmatch(pattern, 'file1.rb', flags) },
          "no grouped pattern matches the root files: #{result.inspect}"
        )
        refute_includes(result, './**/*')
      end
    end
  end
end

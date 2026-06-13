# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

# Proves that --auto-gen-config (TodoGenerator) does not write offenses that
# are already silenced by a per-validator Exclude pattern into the baseline.
# run_linting bypassed Runner#filter_result_offenses, so excluded files were
# counted and added to the todo file.
describe 'TodoGenerator respects per-validator excludes' do
  it 'omits files matched by a validator Exclude from the baseline' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p('lib/excluded')
        FileUtils.mkdir_p('lib/ok')
        File.write('lib/excluded/bad.rb', "class Excluded\nend\n")
        File.write('lib/ok/bad.rb', "class Okay\nend\n")

        config = test_config do |c|
          c.set_validator_config('Documentation/UndocumentedObjects', 'Exclude', ['lib/excluded/**/*'])
        end
        gen = Yard::Lint::TodoGenerator.new(path: 'lib', config: config, force: true, exclude_limit: 15)
        result = gen.send(:run_linting)
        files = result[:violations_by_validator]['Documentation/UndocumentedObjects'] || []

        refute(files.any? { |f| f.include?('excluded') }, "excluded file leaked into the baseline: #{files.inspect}")
        assert(files.any? { |f| f.include?('ok') }, 'non-excluded file should be in the baseline')
      end
    end
  end
end

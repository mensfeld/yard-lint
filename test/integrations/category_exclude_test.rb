# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

describe 'Category-level Exclude' do
  def offense_files(result, validator_name)
    result.offenses.select { |o| o[:validator] == validator_name }.map { |o| o[:location] }
  end

  it 'excludes files for every validator in the category, even one with its own Exclude' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p('lib/generated')
        FileUtils.mkdir_p('lib/legacy')
        FileUtils.mkdir_p('lib/app')
        %w[generated legacy app].each do |name|
          File.write("lib/#{name}/thing.rb", "class #{name.capitalize}Thing\n  def call(arg)\n  end\nend\n")
        end

        config = Yard::Lint::Config.new(
          'AllValidators' => { 'Exclude' => [] },
          'Documentation' => { 'Exclude' => ['lib/generated/**/*'] },
          'Documentation/UndocumentedObjects' => { 'Exclude' => ['lib/legacy/**/*'] }
        )
        result = Yard::Lint.run(path: 'lib', config: config, progress: false)

        objects = offense_files(result, 'Documentation/UndocumentedObjects')
        refute(objects.any? { |f| f.include?('generated') }, "category Exclude ignored: #{objects.inspect}")
        refute(objects.any? { |f| f.include?('legacy') }, "per-validator Exclude ignored: #{objects.inspect}")
        assert(objects.any? { |f| f.include?('lib/app') }, 'non-excluded file should still be reported')

        arguments = offense_files(result, 'Documentation/UndocumentedMethodArguments')
        refute(arguments.any? { |f| f.include?('generated') }, "category Exclude ignored: #{arguments.inspect}")
        assert(arguments.any? { |f| f.include?('legacy') }, 'per-validator Exclude must not leak to siblings')
      end
    end
  end
end

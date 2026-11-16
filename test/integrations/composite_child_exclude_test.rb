# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'open3'

# Proves that a composite child's Exclude holds when it matches every linted file.
# The runner passed an empty file selection, the registry read it as "all files", and
# Documentation/UndocumentedBooleanMethods (whose offenses are not filtered again under
# its own name) reported the excluded files on single-file and --stdin runs.
describe 'Composite child Exclude matching every linted file' do
  attr_reader :project_dir, :bin_path

  before do
    @project_dir = Dir.mktmpdir('yard-lint-child-exclude-test')
    @bin_path = File.expand_path('../../bin/yard-lint', __dir__)

    FileUtils.mkdir_p(File.join(project_dir, 'lib'))
    %w[Q R].each do |name|
      File.write(File.join(project_dir, 'lib', "#{name.downcase}.rb"), <<~RUBY)
        # Doc.
        class #{name}
          # Is it supervised
          def supervised?
            true
          end
        end
      RUBY
    end
  end

  after do
    FileUtils.rm_rf(project_dir)
  end

  def write_exclude(pattern)
    File.write(
      File.join(project_dir, '.yard-lint.yml'),
      "Documentation/UndocumentedBooleanMethods:\n  Exclude:\n    - '#{pattern}'\n"
    )
  end

  def run_yard_lint(*args, stdin_data: '')
    stdout, stderr, = Open3.capture3(
      bin_path, '--no-progress', '--min-coverage', '0', *args,
      chdir: project_dir, stdin_data: stdin_data
    )
    stdout + stderr
  end

  it 'reports only the not excluded file on a directory run' do
    write_exclude('lib/q.rb')
    output = run_yard_lint('lib/')

    refute_includes(output, 'Q#supervised?')
    assert_includes(output, 'R#supervised?')
  end

  it 'reports nothing when the only linted file is excluded' do
    write_exclude('lib/q.rb')

    refute_includes(run_yard_lint('lib/q.rb'), 'supervised?')
  end

  it 'reports nothing for an excluded file linted from stdin' do
    write_exclude('lib/q.rb')
    source = File.read(File.join(project_dir, 'lib', 'q.rb'))

    refute_includes(run_yard_lint('--stdin', 'lib/q.rb', stdin_data: source), 'supervised?')
  end

  it 'reports nothing when the pattern excludes every file of a directory run' do
    write_exclude('lib/*.rb')

    refute_includes(run_yard_lint('lib/'), 'supervised?')
  end
end

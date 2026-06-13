# frozen_string_literal: true

require 'tmpdir'

# Proves that the one-line YARD-warning parsers extract the line number and
# message correctly even when the source file's path contains "line " or
# " in file ". The line regex matched the first "line " anywhere (so a path
# like .../command line tools/x.rb yielded line 0), and the greedy message
# regex matched up to the last " in file " (garbling the message for a path
# containing that substring).
describe 'Warning path parsing' do
  SOURCE = <<~RUBY
    # frozen_string_literal: true

    # A documented class.
    class WeirdPath
      # Does a thing.
      # @bogustag something
      # @return [void]
      def perform
        nil
      end
    end
  RUBY

  def run_in_dir(dirname)
    Dir.mktmpdir do |root|
      subdir = File.join(root, dirname)
      FileUtils.mkdir_p(subdir)
      file = File.join(subdir, 'weird.rb')
      File.write(file, SOURCE)
      config = test_config { |c| c.set_validator_config('Warnings/UnknownTag', 'Enabled', true) }
      Yard::Lint.run(path: file, config: config, progress: false)
    end
  end

  it 'extracts the correct line number when the path contains "line "' do
    result = run_in_dir('command line tools')
    offense = result.offenses.find { |o| o[:name] == 'UnknownTag' && o[:message].include?('@bogustag') }

    refute_nil(offense)
    assert_equal(8, offense[:location_line], 'line number was lost because the path contains "line "')
  end

  it 'does not garble the message when the path contains " in file "' do
    result = run_in_dir('a in file b')
    offense = result.offenses.find { |o| o[:name] == 'UnknownTag' && o[:message].include?('@bogustag') }

    refute_nil(offense)
    # The greedy regex matched up to the path's " in file ", leaking a path
    # fragment into the message. A clean message has no "in file" remnant.
    assert_includes(offense[:message], '@bogustag')
    refute_includes(offense[:message], 'in file', 'a path fragment leaked into the message')
    assert_equal(8, offense[:location_line])
  end
end

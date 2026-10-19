# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

# Proves that `--only` with a composite child validator reports that child's
# offenses. Documentation/UndocumentedBooleanMethods is combined into
# Documentation/UndocumentedObjects, and its results were dropped whenever the
# parent did not run, so `--only Documentation/UndocumentedBooleanMethods`
# always printed "No offenses found".
describe 'Only Composite Child' do
  before do
    @test_dir = Dir.mktmpdir
    @file = File.join(@test_dir, 'checker.rb')
    File.write(@file, <<~RUBY)
      # Checker
      class Checker
        # @overload enabled?
        #   @return [Boolean]
        def enabled?
          true
        end

        def ready?
          true
        end
      end
    RUBY
  end

  after do
    FileUtils.rm_rf(@test_dir)
  end

  # @param only [Array<String>] validators to run, all enabled ones when empty
  # @return [Array<Hash>] offenses found in the test file
  def offenses_for(only)
    config = Yard::Lint::Config.new
    config.only_validators = only
    Yard::Lint.run(path: @file, config: config, progress: false).offenses
  end

  it 'reports the child offense when only the child validator runs' do
    offenses = offenses_for(['Documentation/UndocumentedBooleanMethods'])

    assert_equal(1, offenses.size)
    assert_equal('Documentation/UndocumentedBooleanMethods', offenses.first[:validator])
    assert_includes(offenses.first[:message], 'enabled?')
  end

  it 'reports only the parent offenses when only the parent validator runs' do
    offenses = offenses_for(['Documentation/UndocumentedObjects'])

    assert_equal(1, offenses.size)
    assert_includes(offenses.first[:message], 'ready?')
  end

  it 'reports child offenses once, under the parent, when both run' do
    offenses = offenses_for(
      %w[Documentation/UndocumentedObjects Documentation/UndocumentedBooleanMethods]
    )

    assert_equal(2, offenses.size)
    assert_equal(['Documentation/UndocumentedObjects'], offenses.map { |o| o[:validator] }.uniq)
  end

  it 'reports child offenses once, under the parent, in a normal run' do
    offenses = offenses_for([]).select { |o| o[:name] == 'UndocumentedObject' }

    assert_equal(2, offenses.size)
    assert_equal(['Documentation/UndocumentedObjects'], offenses.map { |o| o[:validator] }.uniq)
  end
end

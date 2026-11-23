# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

# Proves that a documented `?` method without @return gets a message that names the
# missing @return. Documentation/UndocumentedBooleanMethods offenses used the
# Documentation/UndocumentedObjects message, "Documentation required for ...", on a
# method that has documentation.
describe 'Boolean method missing return message' do
  before do
    @test_dir = Dir.mktmpdir
    @file = File.join(@test_dir, 'checker.rb')
    File.write(@file, <<~RUBY)
      # Checker
      class Checker
        # Whether the checker is enabled
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
  # @param raw_config [Hash] user configuration
  # @return [Hash{String => Hash}] offenses found in the test file by element
  def offenses_for(only, raw_config = {})
    config = Yard::Lint::Config.new(raw_config)
    config.only_validators = only
    Yard::Lint.run(path: @file, config: config, progress: false)
              .offenses
              .select { |o| o[:name] == 'UndocumentedObject' }
              .to_h { |o| [o[:element], o] }
  end

  it 'names the missing @return for a documented method in a normal run' do
    offense = offenses_for([]).fetch('Checker#enabled?')

    assert_equal('The `Checker#enabled?` method has no @return tag', offense[:message])
    assert_equal('Documentation/UndocumentedObjects', offense[:validator])
    assert_equal('warning', offense[:severity])
  end

  it 'keeps the documentation required message for an undocumented method' do
    offense = offenses_for([]).fetch('Checker#ready?')

    assert_equal('Documentation required for `Checker#ready?`', offense[:message])
  end

  it 'keeps the parent name and severity for the documented method' do
    offense = offenses_for(
      [],
      'Documentation/UndocumentedObjects' => { 'Severity' => 'convention' },
      'Documentation/UndocumentedBooleanMethods' => { 'Severity' => 'error' }
    ).fetch('Checker#enabled?')

    assert_equal('The `Checker#enabled?` method has no @return tag', offense[:message])
    assert_equal('Documentation/UndocumentedObjects', offense[:validator])
    assert_equal('convention', offense[:severity])
  end

  it 'names the missing @return when only the child validator runs' do
    offense = offenses_for(['Documentation/UndocumentedBooleanMethods']).fetch('Checker#enabled?')

    assert_equal('The `Checker#enabled?` method has no @return tag', offense[:message])
  end
end

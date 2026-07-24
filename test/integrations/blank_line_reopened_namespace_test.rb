# frozen_string_literal: true

describe 'Blank Line Before Definition - foreign comment blocks' do
  attr_reader :fixture_path, :config

  before do
    @fixture_path = File.expand_path('../fixtures/blank_line_reopened', __dir__)
    @config = test_config do |c|
      c.set_validator_config('Documentation/BlankLineBeforeDefinition', 'Enabled', true)
    end
  end

  it 'does not flag a namespace reopening whose documentation lives in another file' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offenses = result.offenses.select do |o|
      o[:name] == 'BlankLineBeforeDefinition' &&
        o[:object_name] == 'ReopenedShared'
    end

    # `ReopenedShared` is documented once (definition.rb) and reopened under a license
    # banner (reopening.rb). The banner is not its docstring, so the blank line between
    # the banner and the reopening must not be reported.
    assert_empty(offenses)
  end

  it 'still flags a definition whose only documentation is detached by a blank line' do
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find do |o|
      o[:name] == 'BlankLineBeforeDefinition' &&
        o[:object_name]&.include?('BlankLineDetachedExample')
    end

    refute_nil(offense, 'expected the genuinely detached docstring to still be reported')
    assert_includes(offense[:message], 'Blank line between documentation and definition')
  end
end

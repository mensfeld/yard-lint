# frozen_string_literal: true

describe 'Yard::Lint::Contracts::CliOptions' do
  def errors_for(options)
    Yard::Lint::Contracts::CliOptions.new.call(options).errors
  end

  it 'accepts no options' do
    assert_empty(errors_for({}))
  end

  it 'accepts valid options' do
    options = { format: 'sarif', min_coverage: 50.0, only: ['Tags/Order'], explain: 'Tags/Order' }

    assert_empty(errors_for(options))
  end

  %w[text json quickfix sarif].each do |format|
    it "accepts format #{format}" do
      assert_empty(errors_for({ format: format }))
    end
  end

  it 'rejects an unknown format' do
    assert_equal(
      { format: "Unknown format 'xml'. Valid formats: text, json, quickfix, sarif" },
      errors_for({ format: 'xml' })
    )
  end

  [0.0, 100.0].each do |value|
    it "accepts min_coverage #{value}" do
      assert_empty(errors_for({ min_coverage: value }))
    end
  end

  [120.0, -5.0, 100.1].each do |value|
    it "rejects min_coverage #{value}" do
      assert_equal(
        { min_coverage: "Invalid --min-coverage: '#{value}'\n  Must be a number between 0 and 100" },
        errors_for({ min_coverage: value })
      )
    end
  end

  it 'rejects unknown validators in only with suggestions and the validator list' do
    message = errors_for({ only: ['Tags/Ordr', 'Tags/Order', 'Nope'] })[:only]
    lines = message.split("\n")

    assert_equal('Unknown validator(s):', lines[0])
    assert_equal('  Tags/Ordr (did you mean: Tags/Order?)', lines[1])
    assert_equal('  Nope', lines[2])
    assert_equal(['', 'Available validators:'], lines[3, 2])
    assert_equal(Yard::Lint::ConfigLoader::ALL_VALIDATORS.map { |v| "  #{v}" }, lines[5..-3])
    assert_equal(['', 'Run `yard-lint --explain VALIDATOR` to see what a validator checks.'], lines[-2..])
  end

  it 'rejects an unknown validator in explain' do
    message = errors_for({ explain: 'Tags/Ordr' })[:explain]

    assert_equal(['Unknown validator(s):', '  Tags/Ordr (did you mean: Tags/Order?)'], message.split("\n")[0, 2])
  end

  it 'reports every invalid option' do
    assert_equal(%i[format min_coverage], errors_for({ format: 'xml', min_coverage: 120.0 }).keys)
  end
end

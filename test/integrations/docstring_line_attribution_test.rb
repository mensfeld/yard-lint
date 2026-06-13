# frozen_string_literal: true

# Proves that docstring-content offenses point at the offending docstring
# line, not at the documented object's definition line. The validators
# already compute a per-line offset within the docstring but used to report
# everything at object.line (the def/class line).
#
# Fixture layout (1-based lines):
#   5: # Processes the input data
#   6: # in several consecutive steps — including validation   <- em dash
#   7: # Note: this can be slow on large inputs                <- informal notation
#   8: # • first step of the pipeline                          <- invalid list marker
#  10: def process; end
describe 'Docstring line attribution' do
  attr_reader :result

  before do
    fixture_path = File.expand_path('../fixtures/docstring_line_attribution.rb', __dir__)
    config = test_config do |c|
      c.set_validator_config('Documentation/TextSubstitution', 'Enabled', true)
    end
    @result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
  end

  it 'reports text substitutions at the line containing the forbidden string' do
    offenses = result.offenses.select { |o| o[:name] == 'TextSubstitution' }

    refute_empty(offenses)

    assert_equal(
      6,
      offenses.first[:location_line],
      'em dash on line 6 must be reported there, not at the def line'
    )
  end

  it 'reports informal notation at the line containing the pattern' do
    offenses = result.offenses.select { |o| o[:name] == 'InformalNotation' }

    refute_empty(offenses)

    assert_equal(
      7,
      offenses.first[:location_line],
      "informal 'Note:' on line 7 must be reported there, not at the def line"
    )
  end

  it 'reports invalid list markers with their absolute source line' do
    offenses = result.offenses.select { |o| o[:name] == 'MarkdownSyntax' }

    refute_empty(offenses)

    assert_includes(
      offenses.first[:message],
      'at line 8',
      'list marker on line 8 must be reported with its source line, not a docstring-relative index'
    )
  end
end

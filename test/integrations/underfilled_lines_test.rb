# frozen_string_literal: true

# End-to-end coverage for Documentation/UnderfilledLines through the full
# Yard::Lint pipeline on a committed fixture. Documentation/LineLength is enabled
# alongside it so the run also exercises the shared Validators::Base#cached_lines
# helper from both validators on the same file.
describe 'Documentation/UnderfilledLines end-to-end' do
  attr_reader :offenses

  before do
    fixture = File.expand_path('fixtures/underfilled_lines.rb', __dir__)
    config = test_config do |c|
      c.set_validator_config('Documentation/UnderfilledLines', 'Enabled', true)
      c.set_validator_config('Documentation/LineLength', 'Enabled', true)
    end
    @offenses = Yard::Lint.run(path: fixture, config: config, progress: false).offenses
  end

  def underfilled
    offenses.select { |o| o[:validator] == 'Documentation/UnderfilledLines' }
  end

  def line_length
    offenses.select { |o| o[:validator] == 'Documentation/LineLength' }
  end

  it 'flags the under-filled paragraph exactly once' do
    assert_equal(1, underfilled.size, "unexpected: #{underfilled.map { |o| o[:message] }}")
  end

  it 'attributes the offense to the fixture with convention severity' do
    assert_includes(underfilled.first[:location], 'underfilled_lines.rb')
    assert_equal('convention', underfilled.first[:severity])
    assert_match(/uses 2 lines but fits in 1/, underfilled.first[:message])
  end

  it 'does not flag the well-filled, semantic-break, list, or single long-line paragraphs' do
    # Only the `underfilled` method qualifies; the other four constructs are
    # one-line, semantically broken, list, or single-line-too-long respectively.
    assert_equal(1, underfilled.size)
  end

  it 'runs LineLength on the same file via the shared base helper' do
    # The fixture's last comment line exceeds 120 chars, so LineLength flags it
    # exactly once - proving both validators read the file through the shared
    # Validators::Base#cached_lines without error.
    assert_equal(1, line_length.size)
  end
end

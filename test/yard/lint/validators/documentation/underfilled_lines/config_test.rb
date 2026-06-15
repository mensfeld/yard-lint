# frozen_string_literal: true

describe 'Yard::Lint::Validators::Documentation::UnderfilledLines::Config' do
  it 'id returns the validator identifier' do
    assert_equal(
      :underfilled_lines,
      Yard::Lint::Validators::Documentation::UnderfilledLines::Config.id
    )
  end

  it 'defaults returns default configuration' do
    assert_equal(
      {
        'Enabled' => false,
        'Severity' => 'convention',
        'MaxLength' => 120,
        'MinTrailingSpace' => 20,
        'MinParagraphLines' => 2,
        'SentenceEndChars' => ['.', '?', '!', ':', ';'],
        'SkipNonAscii' => true
      },
      Yard::Lint::Validators::Documentation::UnderfilledLines::Config.defaults
    )
  end

  it 'defaults is disabled by default' do
    assert_equal(false, Yard::Lint::Validators::Documentation::UnderfilledLines::Config.defaults['Enabled'])
  end

  it 'defaults returns frozen hash' do
    assert_predicate(Yard::Lint::Validators::Documentation::UnderfilledLines::Config.defaults, :frozen?)
  end

  it 'combines with returns empty array for standalone validator' do
    assert_equal([], Yard::Lint::Validators::Documentation::UnderfilledLines::Config.combines_with)
  end

  it 'inheritance inherits from base config class' do
    assert_equal(
      Yard::Lint::Validators::Config,
      Yard::Lint::Validators::Documentation::UnderfilledLines::Config.superclass
    )
  end
end

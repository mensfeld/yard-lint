# frozen_string_literal: true

# Proves that Tags/ExampleSyntax strips YARD "# =>" output markers only when
# they are real trailing comments, not when "# =>" appears inside a string
# literal. The cleaner used `line.sub(/\s*#\s*=>.*$/, '')`, which truncated
# at the first "# =>" anywhere on the line - turning
# `msg = "result # => not output"` into an unterminated string and reporting
# a bogus syntax error on valid example code.
describe 'ExampleSyntax output markers' do
  attr_reader :result

  before do
    fixture_path = File.expand_path('../fixtures/example_output_marker.rb', __dir__)
    @result = Yard::Lint.run(path: fixture_path, config: test_config, progress: false)
  end

  def syntax_error_for(method_name)
    result.offenses.find do |o|
      o[:name] == 'ExampleSyntax' && o[:message].include?(method_name)
    end
  end

  it 'does not flag a string literal that contains a "# =>" sequence' do
    assert_nil(syntax_error_for('announce'), 'a "# =>" inside a string was treated as an output marker')
  end

  it 'still strips a real "# =>" output marker after an expression' do
    assert_nil(syntax_error_for('add'))
  end

  it 'still reports a genuinely broken example' do
    refute_nil(syntax_error_for('really_broken'))
  end
end

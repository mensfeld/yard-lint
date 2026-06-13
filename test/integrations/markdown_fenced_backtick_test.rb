# frozen_string_literal: true

# Proves that Documentation/MarkdownSyntax ignores backticks inside fenced code
# blocks when checking for unclosed inline backticks. It counted every backtick
# (including ``` fences and code content), so a fenced block containing a lone
# backtick produced a spurious "unclosed backtick" offense.
describe 'MarkdownSyntax fenced backticks' do
  attr_reader :result

  before do
    fixture_path = File.expand_path('../fixtures/markdown_fenced_backtick.rb', __dir__)
    @result = Yard::Lint.run(path: fixture_path, config: test_config, progress: false)
  end

  def unclosed_backtick?(method_name)
    result.offenses.any? do |o|
      o[:name] == 'MarkdownSyntax' &&
        o[:message].include?("##{method_name}'") &&
        o[:message].include?('Unclosed backtick')
    end
  end

  it 'does not flag a backtick inside a fenced code block' do
    refute(unclosed_backtick?('build'), 'a backtick inside a fenced code block was counted')
  end

  it 'still flags a genuinely unclosed inline backtick' do
    assert(unclosed_backtick?('unclosed'))
  end
end

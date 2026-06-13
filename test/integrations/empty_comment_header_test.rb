# frozen_string_literal: true

# Proves that Documentation/EmptyCommentLine does not attribute a file-header
# comment (separated from a definition by a blank line) to that definition.
# The upward scan skipped any number of blank lines before the comment block,
# so a header like `# frozen_string_literal: true` + `#` was treated as the
# class's documentation and its bare `#` reported as an empty trailing line -
# even though YARD only attaches a docstring that is immediately above.
describe 'EmptyCommentLine header attribution' do
  attr_reader :result

  before do
    fixture_path = File.expand_path('../fixtures/empty_comment_header.rb', __dir__)
    @result = Yard::Lint.run(path: fixture_path, config: test_config, progress: false)
  end

  def flagged?(object_name)
    result.offenses.any? do |o|
      o[:name] == 'EmptyCommentLine' && o[:message].include?("'#{object_name}'")
    end
  end

  it 'does not attribute a blank-separated file header to the class' do
    refute(flagged?('EmptyCommentHeader'), 'a detached file header was treated as class documentation')
  end

  it 'still flags a real empty trailing comment line in a method docstring' do
    assert(flagged?('EmptyCommentHeader#documented_method'))
  end
end

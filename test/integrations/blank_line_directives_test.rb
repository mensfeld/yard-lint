# frozen_string_literal: true

# Proves that Documentation/BlankLineBeforeDefinition does not treat
# shebangs, Sorbet sigils, RuboCop directives, or a bare `#` comment as
# documentation. The upward scan stopped at the first non-magic comment and
# called it a doc block, so a blank line between such a non-doc comment and a
# definition produced a spurious "blank line between documentation and
# definition" offense for an undocumented class.
describe 'BlankLineBeforeDefinition directives' do
  attr_reader :result

  before do
    fixture_path = File.expand_path('../fixtures/blank_line_directives.rb', __dir__)
    @result = Yard::Lint.run(path: fixture_path, config: test_config, progress: false)
  end

  def flagged?(class_name)
    result.offenses.any? do |o|
      o[:name] == 'BlankLineBeforeDefinition' && o[:message].include?("'#{class_name}'")
    end
  end

  it 'does not flag a class preceded by a Sorbet sigil' do
    refute(flagged?('SigilClass'), 'a Sorbet sigil was treated as documentation')
  end

  it 'does not flag a class preceded by a RuboCop directive' do
    refute(flagged?('RubocopClass'), 'a RuboCop directive was treated as documentation')
  end

  it 'does not flag a class preceded by a bare # comment' do
    refute(flagged?('BareHashClass'), 'a bare # comment was treated as documentation')
  end

  it 'still flags a class with real documentation and a blank line' do
    assert(flagged?('DocumentedWithBlank'))
  end
end

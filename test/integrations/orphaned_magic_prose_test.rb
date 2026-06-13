# frozen_string_literal: true

# Proves that OrphanedDocComment does not treat a prose line that merely starts
# with a magic-comment word (e.g. "encoding: UTF-8 is assumed...") as a magic
# comment. Doing so split the documentation block, leaving the tagged part
# looking orphaned even though a def follows.
describe 'OrphanedDocComment magic-comment prose' do
  it 'does not flag a doc block containing prose starting with "encoding:"' do
    fixture_path = File.expand_path('../fixtures/orphaned_magic_prose.rb', __dir__)
    result = Yard::Lint.run(path: fixture_path, config: test_config, progress: false)

    orphaned = result.offenses.select { |o| o[:name] == 'OrphanedDocComment' }
    assert_empty(orphaned, "prose starting with a magic word split the doc block: #{orphaned.map { |o| o[:message] }}")
  end
end

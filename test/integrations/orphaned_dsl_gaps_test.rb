# frozen_string_literal: true

# Proves that Documentation/OrphanedDocComment does not flag comments attached
# to DSL constructs YARD actually documents: a wrapped def (memoize def), a
# receiver DSL call (Foo.register :x), and a call carrying a @method tag.
describe 'OrphanedDocComment DSL gaps' do
  attr_reader :result

  before do
    fixture_path = File.expand_path('../fixtures/orphaned_dsl_gaps.rb', __dir__)
    @result = Yard::Lint.run(path: fixture_path, config: test_config, progress: false)
  end

  def orphan_lines
    result.offenses.select { |o| o[:name] == 'OrphanedDocComment' }.map { |o| o[:location_line] }
  end

  it 'does not flag a wrapped def (memoize def)' do
    refute_includes(orphan_lines, 5, 'memoize def was flagged as orphaned')
  end

  it 'does not flag a receiver DSL call (Foo.register :x)' do
    refute_includes(orphan_lines, 11, 'receiver DSL call was flagged as orphaned')
  end

  it 'does not flag a call documented with a @method tag' do
    refute_includes(orphan_lines, 16, 'a @method-tagged DSL call was flagged as orphaned')
  end

  it 'still flags a genuinely orphaned tagged comment' do
    assert_includes(orphan_lines, 24)
  end
end

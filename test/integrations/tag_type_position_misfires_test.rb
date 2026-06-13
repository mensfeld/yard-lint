# frozen_string_literal: true

# Proves two TagTypePosition false positives are fixed: under type_first, a
# valid @option (whose grammar requires name before type) must not be flagged;
# and a comment detached from the definition by a blank line must not be
# scanned at all.
describe 'TagTypePosition misfires' do
  def offenses_for(style)
    fixture_path = File.expand_path('../fixtures/tag_type_position_misfires.rb', __dir__)
    config = test_config { |c| c.set_validator_config('Tags/TagTypePosition', 'EnforcedStyle', style) }
    Yard::Lint.run(path: fixture_path, config: config, progress: false)
       .offenses.select { |o| o[:name] == 'TagTypePosition' }
  end

  it 'does not flag a valid @option under type_first' do
    offenses = offenses_for('type_first')
    refute(offenses.any? { |o| o[:message].include?('opts') }, '@option was flagged under type_first')
  end

  it 'does not flag a comment detached by a blank line' do
    # Default style is type_after_name; the detached comment is in type-first
    # form, which would be a violation if (wrongly) attached to #process.
    offenses = offenses_for('type_after_name')
    refute(offenses.any? { |o| o[:message].include?('name') }, 'a detached comment was scanned')
  end
end

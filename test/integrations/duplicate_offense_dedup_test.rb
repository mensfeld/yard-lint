# frozen_string_literal: true

# Proves that identical offenses are reported once. A docstring on
# attr_accessor belongs to both generated methods (reader and writer), so
# YARD warning capture and docstring-scanning validators each produced two
# identical offenses for a single documentation problem, inflating counts.
describe 'Duplicate offense dedup' do
  attr_reader :result

  before do
    fixture_path = File.expand_path('../fixtures/attr_shared_docstring.rb', __dir__)
    config = test_config do |c|
      c.set_validator_config('Documentation/LineLength', 'Enabled', true)
    end
    @result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
  end

  it 'reports an unknown tag on an attr_accessor docstring once' do
    offenses = result.offenses.select do |o|
      o[:name] == 'UnknownTag' && o[:message].include?('@returnz')
    end

    assert_equal(
      1,
      offenses.size,
      'identical UnknownTag offenses for the shared attr_accessor docstring were not deduplicated'
    )
  end

  it 'reports an overlong line on an attr_accessor docstring once' do
    offenses = result.offenses.select { |o| o[:name] == 'LineLength' }

    assert_equal(
      1,
      offenses.size,
      'identical LineLength offenses for the shared attr_accessor docstring were not deduplicated'
    )
  end
end

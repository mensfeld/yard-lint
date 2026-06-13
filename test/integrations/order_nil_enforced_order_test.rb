# frozen_string_literal: true

# Proves that Tags/Order does not crash when EnforcedOrder is explicitly set
# to null in the config. The validator read the config value directly with no
# default fallback, so an explicit `EnforcedOrder: ~` replaced the seeded
# array with nil and `nil.dup` raised, aborting the whole run.
describe 'Tags/Order with nil EnforcedOrder' do
  it 'falls back to the default order instead of crashing' do
    fixture_path = File.expand_path('../fixtures/order_nil_config.rb', __dir__)
    config = test_config { |c| c.set_validator_config('Tags/Order', 'EnforcedOrder', nil) }

    result = nil
    # Must not raise (previously nil.dup raised NoMethodError, aborting the run)
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    offense = result.offenses.find do |o|
      o[:name] == 'InvalidTagOrder' && o[:message].include?('fetch')
    end
    refute_nil(offense, 'expected a tag-order offense using the default order')
  end
end

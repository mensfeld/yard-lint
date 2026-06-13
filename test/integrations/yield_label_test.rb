# frozen_string_literal: true

# Proves that Tags/MissingYield does not treat "yield:" symbol hash keys or
# keyword-argument labels as block yields. The detection regex guarded
# ":yield" and ".yield" but not the label form, so methods building hashes
# like { yield: true } were told to document a block they never yield to.
describe 'Yield label' do
  attr_reader :result

  before do
    fixture_path = File.expand_path('../fixtures/yield_label_methods.rb', __dir__)
    config = test_config do |c|
      c.set_validator_config('Tags/MissingYield', 'Enabled', true)
    end
    @result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
  end

  it 'does not flag methods using yield: as a hash key or keyword label' do
    offenses = result.offenses.select do |o|
      o[:name] == 'MissingYield' &&
        (o[:message].include?('build_flags') || o[:message].include?('configure'))
    end

    assert_empty(offenses, 'yield: labels were treated as block yields')
  end

  it 'still flags methods that genuinely yield without @yield documentation' do
    offenses = result.offenses.select do |o|
      o[:name] == 'MissingYield' && o[:message].include?('each_item')
    end

    refute_empty(offenses)
  end
end

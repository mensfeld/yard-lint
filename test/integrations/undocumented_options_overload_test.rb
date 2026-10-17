# frozen_string_literal: true

# Proves that Documentation/UndocumentedOptions counts @option tags written
# inside @overload blocks. YARD stores them on the overload's own docstring,
# so reading object.tags missed them and reported "no @option tags".
describe 'UndocumentedOptions with @overload' do
  attr_reader :result

  before do
    fixture_path = File.expand_path('../fixtures/undocumented_options_overload.rb', __dir__)
    config = test_config { |c| c.set_validator_config('Documentation/UndocumentedOptions', 'Enabled', true) }
    @result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
  end

  def flagged?(method_name)
    result.offenses.any? do |o|
      o[:name] == 'UndocumentedOptions' && o[:message].include?("##{method_name}'")
    end
  end

  it 'does not flag @option tags documented inside an @overload block' do
    refute(flagged?('connect'), '@option tags inside an @overload block were not counted')
  end

  it 'does not flag @option tags documented at top level' do
    refute(flagged?('bind'))
  end

  it 'still flags an @overload without @option tags' do
    assert(flagged?('listen'))
  end
end

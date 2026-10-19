# frozen_string_literal: true

# Proves that Tags/RedundantParamDescription checks @param and @option tags
# written inside @overload blocks. YARD stores them on the overload's own
# docstring, so reading object.docstring.tags missed them and a redundant
# description was never reported.
describe 'RedundantParamDescription with @overload' do
  attr_reader :result

  before do
    fixture_path = File.expand_path('../fixtures/redundant_param_description_overload.rb', __dir__)
    config = test_config { |c| c.set_validator_config('Tags/RedundantParamDescription', 'Enabled', true) }
    @result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
  end

  def flagged?(description)
    result.offenses.any? do |o|
      o[:name] == 'RedundantParamDescription' && o[:message].include?("'#{description}'")
    end
  end

  it 'flags a redundant @param description inside an @overload block' do
    assert(flagged?('the name'), '@param inside an @overload block was not checked')
  end

  it 'flags a redundant @option description inside an @overload block' do
    assert(flagged?('the port'), '@option inside an @overload block was not checked')
  end

  it 'flags a redundant @param description at top level' do
    assert(flagged?('the title'))
  end

  it 'does not flag a meaningful @param description inside an @overload block' do
    refute(result.offenses.any? { |o| o[:name] == 'RedundantParamDescription' && o[:message].include?('source') })
  end
end

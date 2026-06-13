# frozen_string_literal: true

# Proves the Warnings/UnknownParameterName suggestion engine reads parameters
# from the correct method and parses modern signatures:
#  - it must use the method at the reported line, not an earlier one (BUG-068)
#  - it must parse `def self.foo` receiver methods (BUG-070)
#  - it must not mangle keyword defaults / defaults containing commas (BUG-071)
describe 'UnknownParameterName suggestions' do
  attr_reader :result

  before do
    fixture_path = File.expand_path('../fixtures/unknown_param_suggestions.rb', __dir__)
    config = test_config { |c| c.set_validator_config('Warnings/UnknownParameterName', 'Enabled', true) }
    @result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
  end

  def message_for(unknown)
    result.offenses.find do |o|
      o[:name] == 'UnknownParameterName' && o[:message].include?("name: #{unknown}")
    end&.fetch(:message)
  end

  it 'suggests a param from the method at the reported line, not an earlier one' do
    assert_includes(message_for('chery').to_s, "did you mean 'cherry'?")
  end

  it 'parses receiver (def self.foo) methods' do
    assert_includes(message_for('nme').to_s, "did you mean 'name'?")
  end

  it 'parses keyword args and defaults containing commas' do
    assert_includes(message_for('naem').to_s, "did you mean 'name'?")
  end
end

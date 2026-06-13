# frozen_string_literal: true

# Proves that Semantic/AbstractMethods does not flag an @abstract method whose
# body is a multi-line `raise NotImplementedError, "message"`. The body
# heuristic inspected each stripped line independently, so the continuation
# line holding the message string looked like a real implementation.
describe 'AbstractMethods multiline raise' do
  attr_reader :result

  before do
    fixture_path = File.expand_path('../fixtures/abstract_multiline_raise.rb', __dir__)
    config = test_config do |c|
      c.set_validator_config('Semantic/AbstractMethods', 'Enabled', true)
    end
    @result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
  end

  def violation_for(method_name)
    result.offenses.find do |o|
      o[:name] == 'AbstractMethod' && o[:message].include?("#{method_name}`")
    end
  end

  it 'does not flag a multi-line raise NotImplementedError as an implementation' do
    assert_nil(violation_for('multiline_raise'), 'multi-line raise was treated as a real implementation')
  end

  it 'still flags an abstract method with a real implementation' do
    refute_nil(violation_for('has_real_implementation'))
  end
end

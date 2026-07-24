# frozen_string_literal: true

# Proves that Semantic/AbstractMethods treats a `fail NotImplementedError` guard the same
# as `raise NotImplementedError`. `fail` is a built-in alias of `raise` (`Kernel#fail`), so
# the two forms are identical abstract-method stubs, but AllowedImplementations is written
# with `raise` and the body heuristic matched it literally.
describe 'AbstractMethods fail alias' do
  attr_reader :result

  before do
    fixture_path = File.expand_path('../fixtures/abstract_fail_alias.rb', __dir__)
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

  it 'does not flag `fail NotImplementedError` as an implementation' do
    assert_nil(violation_for('fail_guard'), '`fail NotImplementedError` was treated as a real implementation')
  end

  it 'does not flag a `fail NotImplementedError, message` guard as an implementation' do
    assert_nil(violation_for('fail_with_message'))
  end

  it 'still flags an abstract method with a real implementation' do
    refute_nil(violation_for('has_real_implementation'))
  end
end

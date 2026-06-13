# frozen_string_literal: true

# Proves that Semantic/AbstractMethods honors the AllowedImplementations
# config option, which was previously defined but never read by the validator.
describe 'AbstractMethods AllowedImplementations' do
  attr_reader :fixture_path

  before do
    @fixture_path = File.expand_path('../fixtures/abstract_allowed_impl.rb', __dir__)
  end

  def flagged?(result, method_name)
    result.offenses.any? do |o|
      o[:name] == 'AbstractMethod' && o[:message].include?("##{method_name}`")
    end
  end

  it 'honors a custom AllowedImplementations pattern' do
    config = test_config do |c|
      c.set_validator_config('Semantic/AbstractMethods', 'Enabled', true)
      c.set_validator_config(
        'Semantic/AbstractMethods', 'AllowedImplementations',
        ['raise NotImplementedError', 'raise NotImplementedError, ".+"', 'super']
      )
    end
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    refute(flagged?(result, 'must_implement'), 'custom AllowedImplementations pattern was ignored')
  end

  it 'flags an implementation not covered by the default patterns' do
    config = test_config { |c| c.set_validator_config('Semantic/AbstractMethods', 'Enabled', true) }
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    assert(flagged?(result, 'must_implement'))
  end
end

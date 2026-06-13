# frozen_string_literal: true

# Proves that Documentation/UndocumentedMethodArguments does not demand
# @param tags for block (&block) or splat (*args / **opts) parameters. The
# count compared against the @param tag count used object.parameters.size,
# which includes blocks (documented via @yield, never @param) and splats,
# unlike every other arity computation in the gem (which excludes * and &).
describe 'Block and splat params' do
  attr_reader :result

  before do
    fixture_path = File.expand_path('../fixtures/block_and_splat_params.rb', __dir__)
    @result = Yard::Lint.run(path: fixture_path, config: test_config, progress: false)
  end

  def offense_for(method_name)
    result.offenses.find do |o|
      o[:name] == 'UndocumentedMethodArgument' && o[:message].include?(method_name)
    end
  end

  it 'does not flag a method whose only undocumented param is a block' do
    assert_nil(offense_for('each_limited'), 'block param was demanded as @param')
  end

  it 'does not flag a method whose only param is a splat' do
    assert_nil(offense_for('collect'), 'splat param was demanded as @param')
  end

  it 'does not flag a method whose only param is a double splat' do
    assert_nil(offense_for('forward'), 'double-splat param was demanded as @param')
  end

  it 'still flags a method with genuinely undocumented positional arguments' do
    refute_nil(offense_for('needs_docs'))
  end
end

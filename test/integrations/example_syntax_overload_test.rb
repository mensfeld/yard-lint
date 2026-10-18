# frozen_string_literal: true

# Proves that Tags/ExampleSyntax checks @example tags written inside @overload
# blocks. YARD stores them on the overload's own docstring, so reading
# object.tags missed them and a broken example was never reported.
describe 'ExampleSyntax with @overload' do
  attr_reader :result

  before do
    fixture_path = File.expand_path('../fixtures/example_syntax_overload.rb', __dir__)
    config = test_config { |c| c.set_validator_config('Tags/ExampleSyntax', 'Enabled', true) }
    @result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
  end

  def flagged?(method_name)
    result.offenses.any? do |o|
      o[:name] == 'ExampleSyntax' && o[:message].include?("##{method_name}")
    end
  end

  it 'flags a broken @example inside an @overload block' do
    assert(flagged?('build'), '@example inside an @overload block was not checked')
  end

  it 'flags a broken @example at top level' do
    assert(flagged?('render'))
  end

  it 'does not flag a valid @example inside an @overload block' do
    refute(flagged?('parse'))
  end
end

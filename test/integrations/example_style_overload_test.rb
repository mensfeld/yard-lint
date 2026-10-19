# frozen_string_literal: true

# Proves that Tags/ExampleStyle checks @example tags written inside @overload
# blocks. YARD stores them on the overload's own docstring, so reading
# object.tags missed them and a badly styled example was never reported.
describe 'ExampleStyle with @overload' do
  attr_reader :result

  before do
    skip 'RuboCop not available' unless Yard::Lint::Validators::Tags::ExampleStyle::LinterDetector.rubocop_available?

    fixture_path = File.expand_path('../fixtures/example_style_overload.rb', __dir__)
    config = test_config do |c|
      c.set_validator_config('Tags/ExampleStyle', 'Enabled', true)
      c.set_validator_config('Tags/ExampleStyle', 'Linter', 'rubocop')
    end

    # Lint a copy outside the repo so RuboCop does not pick up the repo's
    # .rubocop.yml, whose plugins are only in Gemfile.lint
    Dir.mktmpdir do |dir|
      file_path = File.join(dir, File.basename(fixture_path))
      FileUtils.cp(fixture_path, file_path)
      @result = Yard::Lint.run(path: file_path, config: config, progress: false)
    end
  end

  def flagged?(example_name)
    result.offenses.any? do |o|
      o[:name] == 'ExampleStyle' && o[:message].include?("'#{example_name}'")
    end
  end

  it 'flags a badly styled @example inside an @overload block' do
    assert(flagged?('Build overload'), '@example inside an @overload block was not checked')
  end

  it 'flags a badly styled @example at top level' do
    assert(flagged?('Render top level'))
  end

  it 'does not flag a well styled @example inside an @overload block' do
    refute(flagged?('Parse overload'))
  end
end

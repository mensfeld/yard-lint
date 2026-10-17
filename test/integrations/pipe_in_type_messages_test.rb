# frozen_string_literal: true

# Proves that Tags/InvalidTypes and Tags/TypeSyntax keep '|' (and '%') from the
# type text in their messages, although '|' also separates the fields in the
# validator output.
describe 'Pipe in type messages' do
  attr_reader :fixture_path, :config

  before do
    @fixture_path = File.expand_path('../fixtures/pipe_in_type.rb', __dir__)
    @config = test_config do |c|
      c.set_validator_config('Tags/InvalidTypes', 'Enabled', true)
      c.set_validator_config('Tags/TypeSyntax', 'Enabled', true)
    end
  end

  # @param name [String] offense name
  # @param method_name [String] method the offense is reported on
  # @return [String, nil] message of the matching offense
  def message_for(name, method_name)
    line = File.readlines(fixture_path).index { |l| l.include?("def #{method_name}") } + 1
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
    result.offenses.find { |o| o[:name] == name && o[:line] == line }&.fetch(:message)
  end

  it 'InvalidTypes reports the pipe token for a spaced union' do
    assert_equal('The `find` has invalid type(s): @return: `|`', message_for('InvalidTagType', 'find'))
  end

  it 'InvalidTypes reports the whole type for an unspaced union' do
    assert_equal(
      'The `fetch` has invalid type(s): @param key: `Symbol|String`',
      message_for('InvalidTagType', 'fetch')
    )
  end

  it 'InvalidTypes keeps a percent sign next to a pipe' do
    assert_equal('The `rate` has invalid type(s): @return: `Rate%|nil`', message_for('InvalidTagType', 'rate'))
  end

  it 'TypeSyntax reports the full type and the error' do
    assert_equal(
      "Invalid type syntax in @return tag: 'String | nil' (invalid character at |)",
      message_for('InvalidTypeSyntax', 'find')
    )
  end

  it 'TypeSyntax keeps a percent sign next to a pipe' do
    assert_includes(message_for('InvalidTypeSyntax', 'rate'), "'Rate%|nil'")
  end
end

# frozen_string_literal: true

# Proves that Tags/CollectionType produces a valid (balanced) long-syntax
# suggestion for a nested short-style Hash. The non-greedy regex used before
# produced `Hash{Symbol => Hash<String, Integer}>` (mismatched braces).
describe 'CollectionType nested suggestion' do
  it 'suggests a balanced nested long syntax' do
    fixture_path = File.expand_path('../fixtures/collection_type_nested.rb', __dir__)
    result = Yard::Lint.run(path: fixture_path, config: test_config, progress: false)

    offense = result.offenses.find { |o| o[:name] == 'CollectionType' }
    refute_nil(offense)
    assert_includes(offense[:message], 'Hash{Symbol => Hash{String => Integer}}')
    refute_includes(offense[:message], 'Integer}>', 'suggestion has mismatched brackets')
  end
end

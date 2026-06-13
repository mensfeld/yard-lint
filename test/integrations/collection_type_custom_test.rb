# frozen_string_literal: true

# Proves that Tags/CollectionType only matches the built-in Hash and Array
# collection types, not custom classes whose names merely contain "Hash" or
# "Array" (e.g. MyHash, ByteArray). The detection regexes used unanchored
# substring matches, so `MyHash<String, Integer>` was flagged with a nonsense
# `MyHash{String => Integer}` suggestion.
describe 'CollectionType custom classes' do
  def offenses_for(fixture_result)
    fixture_result.offenses.select { |o| o[:name] == 'CollectionType' }
  end

  it 'does not flag a custom Hash-like class under the default (long) style' do
    fixture_path = File.expand_path('../fixtures/collection_type_custom.rb', __dir__)
    result = Yard::Lint.run(path: fixture_path, config: test_config, progress: false)

    refute(offenses_for(result).any? { |o| o[:message].include?('MyHash') },
           'a custom MyHash class was flagged as a collection-style violation')
    # The genuine short-style Hash is still flagged
    assert(offenses_for(result).any? { |o| o[:message].include?('Hash<Symbol, String>') })
  end

  it 'does not flag a custom Array-like class under the short style' do
    fixture_path = File.expand_path('../fixtures/collection_type_custom.rb', __dir__)
    config = test_config { |c| c.set_validator_config('Tags/CollectionType', 'EnforcedStyle', 'short') }
    result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

    refute(offenses_for(result).any? { |o| o[:message].include?('ByteArray') },
           'a custom ByteArray class was flagged as a collection-style violation')
  end
end

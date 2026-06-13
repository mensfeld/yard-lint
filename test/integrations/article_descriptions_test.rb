# frozen_string_literal: true

# Proves that Tags/RedundantParamDescription treats only whole-word articles
# ("a", "an", "the") as articles. The matching regex was an unanchored
# prefix, so any description word starting with those letters (authenticated,
# auto-generated) marked a meaningful description as redundant.
describe 'Article descriptions' do
  attr_reader :result

  before do
    fixture_path = File.expand_path('../fixtures/article_descriptions.rb', __dir__)
    @result = Yard::Lint.run(path: fixture_path, config: test_config, progress: false)
  end

  it 'does not flag descriptions whose first word merely starts with an article' do
    offenses = result.offenses.select do |o|
      o[:name] == 'RedundantParamDescription' &&
        ["'authenticated user'", "'auto-generated id'", "'themed style'"]
          .any? { |desc| o[:message].include?(desc) }
    end

    assert_empty(offenses, 'meaningful descriptions were flagged as redundant')
  end

  it 'still flags descriptions that are a bare article plus the parameter name' do
    offenses = result.offenses.select do |o|
      o[:name] == 'RedundantParamDescription' && o[:message].include?("'the name'")
    end

    refute_empty(offenses)
  end
end

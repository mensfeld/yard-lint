# frozen_string_literal: true

# Proves that Tags/ApiTags only requires @api on classes, modules, and
# methods (as its documentation states), not on constants. The missing-tag
# branch flagged any public non-root object, so a top-level constant was
# reported as "missing @api tag".
describe 'ApiTags on constants' do
  attr_reader :result

  before do
    fixture_path = File.expand_path('../fixtures/api_tag_constants.rb', __dir__)
    config = test_config do |c|
      c.set_validator_config('Tags/ApiTags', 'Enabled', true)
    end
    @result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
  end

  def missing_api_for(name)
    result.offenses.find do |o|
      o[:name] == 'ApiTag' && o[:message].include?('missing') && o[:message].include?("`#{name}`")
    end
  end

  it 'does not require @api on a constant' do
    assert_nil(missing_api_for('MAX_RETRIES'), 'a constant was required to have an @api tag')
  end

  it 'still requires @api on a class' do
    refute_nil(missing_api_for('NeedsApi'))
  end
end

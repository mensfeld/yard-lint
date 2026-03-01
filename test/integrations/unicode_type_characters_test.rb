# frozen_string_literal: true

require 'test_helper'


describe 'Unicode Type Characters' do
  attr_reader :fixture_path, :config


  before do
    @fixture_path = File.expand_path('../fixtures/unicode_type_characters.rb', __dir__)
  end

  # -- When type specification contains Unicode characters (enabled) --

  def setup_non_ascii_enabled
    @config = test_config do |c|
      c.set_validator_config('Tags/NonAsciiType', 'Enabled', true)
    end
  end

  it 'when type specification contains unicode characters does not crash with encoding compatibility error' do
    setup_non_ascii_enabled

    # Issue #39: yard-lint crashes with "invalid byte sequence in UTF-8"
    # when encountering Unicode characters in type specifications
    # instead of handling them gracefully
    Yard::Lint.run(path: fixture_path, config: config)
  end

  it 'when type specification contains unicode characters continues processing and returns a valid result' do
    setup_non_ascii_enabled

    result = Yard::Lint.run(path: fixture_path, config: config)

    assert_respond_to(result, :offenses)
    assert_kind_of(Array, result.offenses)
  end

  it 'when type specification contains unicode characters reports nonasciitype offenses for each method' do
    setup_non_ascii_enabled

    result = Yard::Lint.run(path: fixture_path, config: config)

    non_ascii_offenses = result.offenses.select { |o| o[:name] == 'NonAsciiType' }

    # Should detect the 3 methods with Unicode characters in type specs:
    # - unicode_ellipsis (...)
    # - unicode_arrow (->)
    # - unicode_em_dash (--)
    assert_equal(3, non_ascii_offenses.size)
  end

  it 'when type specification contains unicode characters includes the unicode character and code point in the message' do
    setup_non_ascii_enabled

    result = Yard::Lint.run(path: fixture_path, config: config)

    non_ascii_offenses = result.offenses.select { |o| o[:name] == 'NonAsciiType' }

    non_ascii_offenses.each do |offense|
      assert_match(/U\+[0-9A-F]{4}/, offense[:message])
    end
  end

  it 'when type specification contains unicode characters does not report offenses for valid ascii type specifications' do
    setup_non_ascii_enabled

    result = Yard::Lint.run(path: fixture_path, config: config)

    non_ascii_offenses = result.offenses.select { |o| o[:name] == 'NonAsciiType' }

    valid_method_offenses = non_ascii_offenses.select do |o|
      o[:method_name]&.include?('valid_ascii_types')
    end

    assert_empty(valid_method_offenses)
  end

  it 'when type specification contains unicode characters detects horizontal ellipsis u 2026' do
    setup_non_ascii_enabled

    result = Yard::Lint.run(path: fixture_path, config: config)

    ellipsis_offenses = result.offenses.select do |o|
      o[:name] == 'NonAsciiType' && o[:message]&.include?('U+2026')
    end

    assert_equal(1, ellipsis_offenses.size)
    assert_includes(ellipsis_offenses.first[:message], "'…'")
  end

  it 'when type specification contains unicode characters detects right arrow u 2192' do
    setup_non_ascii_enabled

    result = Yard::Lint.run(path: fixture_path, config: config)

    arrow_offenses = result.offenses.select do |o|
      o[:name] == 'NonAsciiType' && o[:message]&.include?('U+2192')
    end

    assert_equal(1, arrow_offenses.size)
    assert_includes(arrow_offenses.first[:message], "'→'")
  end

  it 'when type specification contains unicode characters detects em dash u 2014' do
    setup_non_ascii_enabled

    result = Yard::Lint.run(path: fixture_path, config: config)

    em_dash_offenses = result.offenses.select do |o|
      o[:name] == 'NonAsciiType' && o[:message]&.include?('U+2014')
    end

    assert_equal(1, em_dash_offenses.size)
    assert_includes(em_dash_offenses.first[:message], "'—'")
  end

  it 'when type specification contains unicode characters includes helpful guidance in the error message' do
    setup_non_ascii_enabled

    result = Yard::Lint.run(path: fixture_path, config: config)

    non_ascii_offenses = result.offenses.select { |o| o[:name] == 'NonAsciiType' }

    non_ascii_offenses.each do |offense|
      assert_includes(offense[:message], 'Ruby type names must use ASCII characters only')
    end
  end

  it 'when type specification contains unicode characters sets severity to warning' do
    setup_non_ascii_enabled

    result = Yard::Lint.run(path: fixture_path, config: config)

    non_ascii_offenses = result.offenses.select { |o| o[:name] == 'NonAsciiType' }

    non_ascii_offenses.each do |offense|
      assert_equal('warning', offense[:severity])
    end
  end

  it 'when type specification contains unicode characters provides correct file location' do
    setup_non_ascii_enabled

    result = Yard::Lint.run(path: fixture_path, config: config)

    non_ascii_offenses = result.offenses.select { |o| o[:name] == 'NonAsciiType' }

    non_ascii_offenses.each do |offense|
      assert_includes(offense[:location], 'unicode_type_characters.rb')
    end
  end

  # -- When validator is disabled --

  def setup_non_ascii_disabled
    @config = test_config do |c|
      c.set_validator_config('Tags/NonAsciiType', 'Enabled', false)
    end
  end

  it 'when validator is disabled does not report nonasciitype offenses' do
    setup_non_ascii_disabled

    result = Yard::Lint.run(path: fixture_path, config: config)

    non_ascii_offenses = result.offenses.select { |o| o[:name] == 'NonAsciiType' }
    assert_empty(non_ascii_offenses)
  end

  it 'when validator is disabled still does not crash with encoding errors' do
    setup_non_ascii_disabled

    Yard::Lint.run(path: fixture_path, config: config)
  end

  # -- Interaction with TypeSyntax validator --

  def setup_non_ascii_with_type_syntax
    @config = test_config do |c|
      c.set_validator_config('Tags/NonAsciiType', 'Enabled', true)
      c.set_validator_config('Tags/TypeSyntax', 'Enabled', true)
    end
  end

  it 'interaction with typesyntax validator both validators can run together without crashing' do
    setup_non_ascii_with_type_syntax

    Yard::Lint.run(path: fixture_path, config: config)
  end

  it 'interaction with typesyntax validator nonasciitype reports its offenses independently' do
    setup_non_ascii_with_type_syntax

    result = Yard::Lint.run(path: fixture_path, config: config)

    non_ascii_offenses = result.offenses.select { |o| o[:name] == 'NonAsciiType' }
    assert_equal(3, non_ascii_offenses.size)
  end

  # -- With custom ValidatedTags configuration --

  it 'with custom validatedtags configuration only validates configured tags' do
    @config = test_config do |c|
      c.set_validator_config('Tags/NonAsciiType', 'Enabled', true)
      c.set_validator_config('Tags/NonAsciiType', 'ValidatedTags', %w[return])
    end

    result = Yard::Lint.run(path: fixture_path, config: config)

    non_ascii_offenses = result.offenses.select { |o| o[:name] == 'NonAsciiType' }

    # Only @return tags should be checked, so only unicode_arrow should be detected
    # (it's the only one with Unicode in the @return tag in the fixture)
    assert_operator(non_ascii_offenses.size, :<=, 1)
  end
end

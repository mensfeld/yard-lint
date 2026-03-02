# frozen_string_literal: true

# Shared test methods for OneLineBase parser tests
# All Stats parsers inherit from OneLineBase and follow the same pattern
module OneLineBaseParserTests
  def test_parses_warning_data_correctly
    result = @parser.call(@example_input)

    assert_kind_of(Array, result)
    assert_equal(1, result.size)

    offense = result.first
    assert_equal(@expected_output[:name], offense[:name])
    assert_equal(@expected_output[:message], offense[:message])
    assert_equal(@expected_output[:location], offense[:location])
    assert_equal(@expected_output[:line], offense[:line])
  end

  def test_parses_multiple_warnings
    multiple_input = "#{@example_input}\n#{@example_input}"
    result = @parser.call(multiple_input)

    assert_kind_of(Array, result)
    assert_equal(2, result.size)
    result.each do |r|
      assert(r.key?(:name))
      assert(r.key?(:message))
      assert(r.key?(:location))
      assert(r.key?(:line))
    end
  end

  def test_returns_empty_array_for_empty_input
    result = @parser.call('')
    assert_equal([], result)
  end

  def test_returns_empty_array_for_non_matching_input
    result = @parser.call('This is not a yard warning')
    assert_equal([], result)
  end

  def test_only_parses_matching_lines
    mixed_input = "Some other text\n#{@example_input}\nMore text"
    result = @parser.call(mixed_input)
    assert_equal(1, result.size)
  end

  def test_defines_all_required_regexps
    regexps = @parser.class.regexps
    assert_includes(regexps.keys, :general)
    assert_includes(regexps.keys, :message)
    assert_includes(regexps.keys, :location)
    assert_includes(regexps.keys, :line)
  end

  def test_has_frozen_regexps_hash
    assert_predicate(@parser.class.regexps, :frozen?)
  end
end

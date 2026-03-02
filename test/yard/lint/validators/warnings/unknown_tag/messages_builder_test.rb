# frozen_string_literal: true

describe 'Yard::Lint::Validators::Warnings::UnknownTag::MessagesBuilder' do
  attr_reader :messages_builder

  before do
    @messages_builder = Yard::Lint::Validators::Warnings::UnknownTag::MessagesBuilder
  end

  it 'call when offense has no message returns default message' do
    offense = { location: '/tmp/test.rb', line: 10 }
    result = messages_builder.call(offense)
    assert_equal('Unknown tag detected', result)
  end

  it 'call when message does not match expected format returns the message as is' do
    offense = { message: 'Some other error', location: '/tmp/test.rb', line: 10 }
    result = messages_builder.call(offense)
    assert_equal('Some other error', result)
  end

  it 'call when message matches unknown tag format adds did you mean suggestion for returns' do
    offense = {
      message: 'Unknown tag @returns in file `/tmp/test.rb` near line 10',
      location: '/tmp/test.rb',
      line: 10
    }
    result = messages_builder.call(offense)
    assert_equal("Unknown tag @returns (did you mean '@return'?) in file `/tmp/test.rb` near line 10", result)
  end

  it 'call when message matches unknown tag format adds did you mean suggestion for raises' do
    offense = {
      message: 'Unknown tag @raises in file `/tmp/test.rb` near line 15',
      location: '/tmp/test.rb',
      line: 15
    }
    result = messages_builder.call(offense)
    assert_equal("Unknown tag @raises (did you mean '@raise'?) in file `/tmp/test.rb` near line 15", result)
  end

  it 'call when message matches unknown tag format adds did you mean suggestion for params' do
    offense = {
      message: 'Unknown tag @params in file `/tmp/test.rb` near line 20',
      location: '/tmp/test.rb',
      line: 20
    }
    result = messages_builder.call(offense)
    assert_equal("Unknown tag @params (did you mean '@param'?) in file `/tmp/test.rb` near line 20", result)
  end

  it 'call when message matches unknown tag format adds did you mean suggestion for exampl' do
    offense = {
      message: 'Unknown tag @exampl in file `/tmp/test.rb` near line 25',
      location: '/tmp/test.rb',
      line: 25
    }
    result = messages_builder.call(offense)
    assert_equal("Unknown tag @exampl (did you mean '@example'?) in file `/tmp/test.rb` near line 25", result)
  end

  it 'call when message matches unknown tag format adds did you mean suggestion for auhtor' do
    offense = {
      message: 'Unknown tag @auhtor in file `/tmp/test.rb` near line 30',
      location: '/tmp/test.rb',
      line: 30
    }
    result = messages_builder.call(offense)
    assert_equal("Unknown tag @auhtor (did you mean '@author'?) in file `/tmp/test.rb` near line 30", result)
  end

  it 'call when message matches unknown tag format adds did you mean suggestion for deprected' do
    offense = {
      message: 'Unknown tag @deprected in file `/tmp/test.rb` near line 35',
      location: '/tmp/test.rb',
      line: 35
    }
    result = messages_builder.call(offense)
    assert_equal("Unknown tag @deprected (did you mean '@deprecated'?) in file `/tmp/test.rb` near line 35", result)
  end

  it 'call when message matches unknown tag format returns original message when no similar tag found' do
    offense = {
      message: 'Unknown tag @completelywrong in file `/tmp/test.rb` near line 40',
      location: '/tmp/test.rb',
      line: 40
    }
    result = messages_builder.call(offense)
    assert_equal('Unknown tag @completelywrong in file `/tmp/test.rb` near line 40', result)
  end

  it 'call when message matches unknown tag format returns original message when tag is too different' do
    offense = {
      message: 'Unknown tag @xyz in file `/tmp/test.rb` near line 45',
      location: '/tmp/test.rb',
      line: 45
    }
    result = messages_builder.call(offense)
    assert_equal('Unknown tag @xyz in file `/tmp/test.rb` near line 45', result)
  end

  it 'known tags includes standard yard meta data tags' do
    tags = Yard::Lint::Validators::Warnings::UnknownTag::MessagesBuilder.known_tags
    assert_includes(tags, 'param')
    assert_includes(tags, 'return')
    assert_includes(tags, 'raise')
    assert_includes(tags, 'example')
    assert_includes(tags, 'author')
  end

  it 'known tags returns tags dynamically from yard tags library' do
    assert_operator(Yard::Lint::Validators::Warnings::UnknownTag::MessagesBuilder.known_tags.size, :>=, 22)
  end

  it 'known tags all tags are lowercase strings' do
    Yard::Lint::Validators::Warnings::UnknownTag::MessagesBuilder.known_tags.each do |tag|
      assert_kind_of(String, tag)
      assert_equal(tag.downcase, tag)
    end
  end

  it 'known tags caches the result' do
    first_call = Yard::Lint::Validators::Warnings::UnknownTag::MessagesBuilder.known_tags
    second_call = Yard::Lint::Validators::Warnings::UnknownTag::MessagesBuilder.known_tags
    assert_equal(first_call.object_id, second_call.object_id)
  end

  it 'known directives includes standard yard directives' do
    directives = Yard::Lint::Validators::Warnings::UnknownTag::MessagesBuilder.known_directives
    assert_includes(directives, 'attribute')
    assert_includes(directives, 'method')
    assert_includes(directives, 'macro')
  end

  it 'known directives returns directives dynamically from yard tags library' do
    assert_operator(Yard::Lint::Validators::Warnings::UnknownTag::MessagesBuilder.known_directives.size, :>=, 8)
  end

  it 'known directives all directives are lowercase strings' do
    Yard::Lint::Validators::Warnings::UnknownTag::MessagesBuilder.known_directives.each do |directive|
      assert_kind_of(String, directive)
      assert_equal(directive.downcase, directive)
    end
  end

  it 'known directives caches the result' do
    first_call = Yard::Lint::Validators::Warnings::UnknownTag::MessagesBuilder.known_directives
    second_call = Yard::Lint::Validators::Warnings::UnknownTag::MessagesBuilder.known_directives
    assert_equal(first_call.object_id, second_call.object_id)
  end

  it 'all known tags combines tags and directives' do
    expected_size = Yard::Lint::Validators::Warnings::UnknownTag::MessagesBuilder.known_tags.size +
                    Yard::Lint::Validators::Warnings::UnknownTag::MessagesBuilder.known_directives.size
    assert_equal(expected_size, Yard::Lint::Validators::Warnings::UnknownTag::MessagesBuilder.all_known_tags.size)
  end

  it 'all known tags includes both tags and directives' do
    all_tags = Yard::Lint::Validators::Warnings::UnknownTag::MessagesBuilder.all_known_tags
    assert_includes(all_tags, 'param')
    assert_includes(all_tags, 'attribute')
  end

  it 'all known tags caches the result' do
    first_call = Yard::Lint::Validators::Warnings::UnknownTag::MessagesBuilder.all_known_tags
    second_call = Yard::Lint::Validators::Warnings::UnknownTag::MessagesBuilder.all_known_tags
    assert_equal(first_call.object_id, second_call.object_id)
  end

  it 'levenshtein distance calculates distance between identical strings' do
    distance = messages_builder.send(:levenshtein_distance, 'hello', 'hello')
    assert_equal(0, distance)
  end

  it 'levenshtein distance calculates distance for returns vs return' do
    distance = messages_builder.send(:levenshtein_distance, 'returns', 'return')
    assert_equal(1, distance)
  end

  it 'levenshtein distance calculates distance for raises vs raise' do
    distance = messages_builder.send(:levenshtein_distance, 'raises', 'raise')
    assert_equal(1, distance)
  end

  it 'levenshtein distance calculates distance with empty string' do
    distance = messages_builder.send(:levenshtein_distance, '', 'hello')
    assert_equal(5, distance)

    distance = messages_builder.send(:levenshtein_distance, 'hello', '')
    assert_equal(5, distance)
  end

  it 'suggestion finder finds best match for returns' do
    suggestion = messages_builder.send(:find_suggestion, 'returns')
    assert_equal('return', suggestion)
  end

  it 'suggestion finder finds best match for raises' do
    suggestion = messages_builder.send(:find_suggestion, 'raises')
    assert_equal('raise', suggestion)
  end

  it 'suggestion finder finds best match for params' do
    suggestion = messages_builder.send(:find_suggestion, 'params')
    assert_equal('param', suggestion)
  end

  it 'suggestion finder finds best match for exampl' do
    suggestion = messages_builder.send(:find_suggestion, 'exampl')
    assert_equal('example', suggestion)
  end

  it 'suggestion finder finds best match for auhtor' do
    suggestion = messages_builder.send(:find_suggestion, 'auhtor')
    assert_equal('author', suggestion)
  end

  it 'suggestion finder finds best match for deprected' do
    suggestion = messages_builder.send(:find_suggestion, 'deprected')
    assert_equal('deprecated', suggestion)
  end

  it 'suggestion finder returns nil when no good match exists' do
    suggestion = messages_builder.send(:find_suggestion, 'xyz')
    assert_nil(suggestion)
  end

  it 'suggestion finder returns nil when tag name is empty' do
    suggestion = messages_builder.send(:find_suggestion, '')
    assert_nil(suggestion)
  end

  it 'suggestion finder uses didyoumean when available' do
    # DidYouMean is very good at detecting common typos
    suggestion = messages_builder.send(:find_suggestion, 'retur')
    assert_equal('return', suggestion)
  end

  it 'suggestion finder finds directive suggestions' do
    suggestion = messages_builder.send(:find_suggestion, 'attribut')
    assert_equal('attribute', suggestion)
  end

  it 'fallback suggestion finder finds suggestion using levenshtein distance' do
    suggestion = messages_builder.send(:find_suggestion_fallback, 'returns')
    assert_equal('return', suggestion)
  end

  it 'fallback suggestion finder returns nil for very different strings' do
    suggestion = messages_builder.send(:find_suggestion_fallback, 'completelydifferent')
    assert_nil(suggestion)
  end

  it 'fallback suggestion finder respects distance threshold' do
    # Should not suggest when distance is more than half the length
    suggestion = messages_builder.send(:find_suggestion_fallback, 'xxxxxxx')
    assert_nil(suggestion)
  end
end


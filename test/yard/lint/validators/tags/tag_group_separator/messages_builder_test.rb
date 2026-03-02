# frozen_string_literal: true

describe 'Yard::Lint::Validators::Tags::TagGroupSeparator::MessagesBuilder' do
  it 'call with single missing separator generates message for single transition' do
    offense = {
      method_name: 'call',
      separators: 'param->return'
    }
    message = Yard::Lint::Validators::Tags::TagGroupSeparator::MessagesBuilder.call(offense)
    assert_equal(
      'The `call` is missing a blank line between `param` and `return` tag groups.',
      message
    )
  end

  it 'call with multiple missing separators generates message listing all transitions' do
    offense = {
      method_name: 'process',
      separators: 'param->return,return->error'
    }
    message = Yard::Lint::Validators::Tags::TagGroupSeparator::MessagesBuilder.call(offense)
    assert_equal(
      'The `process` is missing blank lines between tag groups: ' \
      '`param` -> `return`, `return` -> `error`.',
      message
    )
  end

  it 'call with description to tag transition handles description group in message' do
    offense = {
      method_name: 'initialize',
      separators: 'description->param'
    }
    message = Yard::Lint::Validators::Tags::TagGroupSeparator::MessagesBuilder.call(offense)
    assert_equal(
      'The `initialize` is missing a blank line between `description` and `param` tag groups.',
      message
    )
  end
end


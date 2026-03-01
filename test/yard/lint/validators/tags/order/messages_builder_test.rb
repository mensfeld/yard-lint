# frozen_string_literal: true

require 'test_helper'


describe 'Yard::Lint::Validators::Tags::Order::MessagesBuilder' do
  it 'call builds message for invalid tag order' do
    offense = {
      method_name: 'calculate',
      order: 'param,return,raise'
    }

    message = Yard::Lint::Validators::Tags::Order::MessagesBuilder.call(offense)

    assert_equal(
      'The `calculate` has yard tags in an invalid order. ' \
      'Following tags need to be in the presented order: `param`, `return`, `raise`.',
      message
    )
  end

  it 'call builds message with single tag' do
    offense = {
      method_name: 'process',
      order: 'param'
    }

    message = Yard::Lint::Validators::Tags::Order::MessagesBuilder.call(offense)

    assert_equal(
      'The `process` has yard tags in an invalid order. ' \
      'Following tags need to be in the presented order: `param`.',
      message
    )
  end
end


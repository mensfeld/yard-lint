# frozen_string_literal: true

require 'test_helper'


describe 'Yard::Lint::Validators::Tags::OptionTags::MessagesBuilder' do
  it 'call builds message for missing option tags' do
    offense = { method_name: 'initialize' }

    message = Yard::Lint::Validators::Tags::OptionTags::MessagesBuilder.call(offense)

    assert_equal(
      'Method `initialize` has options parameter but no @option tags ' \
      'documenting the available options',
      message
    )
  end

  it 'call builds message for instance method' do
    offense = { method_name: 'MyClass#configure' }

    message = Yard::Lint::Validators::Tags::OptionTags::MessagesBuilder.call(offense)

    assert_equal(
      'Method `MyClass#configure` has options parameter but no @option tags ' \
      'documenting the available options',
      message
    )
  end
end

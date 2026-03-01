# frozen_string_literal: true

require 'test_helper'


describe 'Yard::Lint::Validators::Tags::ApiTags::MessagesBuilder' do
  it 'call builds message for missing api tag' do
    offense = {
      object_name: 'MyClass#method',
      status: 'missing'
    }

    message = Yard::Lint::Validators::Tags::ApiTags::MessagesBuilder.call(offense)

    assert_equal('Public object `MyClass#method` is missing @api tag', message)
  end

  it 'call builds message for invalid api tag with api value' do
    offense = {
      object_name: 'MyClass#method',
      status: 'invalid:internal',
      api_value: 'internal'
    }

    message = Yard::Lint::Validators::Tags::ApiTags::MessagesBuilder.call(offense)

    assert_equal("Object `MyClass#method` has invalid @api tag value: 'internal'", message)
  end

  it 'call builds message for invalid api tag from status' do
    offense = {
      object_name: 'MyClass',
      status: 'invalid:deprecated'
    }

    message = Yard::Lint::Validators::Tags::ApiTags::MessagesBuilder.call(offense)

    assert_equal("Object `MyClass` has invalid @api tag value: 'deprecated'", message)
  end
end

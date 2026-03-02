# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Validators::Tags::TagTypePosition::MessagesBuilder' do
  it 'call when enforcing type first but found type after name formats message correctly for param ta' do
      offense = {
        tag_name: 'param',
        param_name: 'user',
        type_info: 'String',
        detected_style: 'type_after_name'
      }

      message = Yard::Lint::Validators::Tags::TagTypePosition::MessagesBuilder.call(offense)

      end
  it 'call when enforcing type first but found type after name formats message correctly for option t' do
      offense = {
        tag_name: 'option',
        param_name: 'opts',
        type_info: 'Hash',
        detected_style: 'type_after_name'
      }

      message = Yard::Lint::Validators::Tags::TagTypePosition::MessagesBuilder.call(offense)

      end
  it 'call when enforcing type after name but found type first formats message correctly for param ta' do
      offense = {
        tag_name: 'param',
        param_name: 'name',
        type_info: 'String',
        detected_style: 'type_first'
      }

      message = Yard::Lint::Validators::Tags::TagTypePosition::MessagesBuilder.call(offense)

      end
  it 'call when enforcing type after name but found type first formats message correctly for option t' do
      offense = {
        tag_name: 'option',
        param_name: 'config',
        type_info: 'Hash{Symbol => Object}',
        detected_style: 'type_first'
      }

      message = Yard::Lint::Validators::Tags::TagTypePosition::MessagesBuilder.call(offense)

      end
  it 'call with complex type annotations handles nested types correctly' do
      offense = {
        tag_name: 'param',
        param_name: 'options',
        type_info: 'Hash{String => Array<Integer>}',
        detected_style: 'type_after_name'
      }

      message = Yard::Lint::Validators::Tags::TagTypePosition::MessagesBuilder.call(offense)

      end
end


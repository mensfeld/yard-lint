# frozen_string_literal: true

require 'test_helper'

describe 'Yard::Lint::Validators::Tags::CollectionType::MessagesBuilder' do
  it 'call when enforcing long style short detected formats message for hash k v to hash k v' do
      offense = {
        tag_name: 'param',
        type_string: 'Hash<Symbol, String>',
        detected_style: 'short'
      }

      message = Yard::Lint::Validators::Tags::CollectionType::MessagesBuilder.call(offense)

      end
  it 'call when enforcing long style short detected formats message for k v to hash k v' do
      offense = {
        tag_name: 'return',
        type_string: '{Symbol => String}',
        detected_style: 'short'
      }

      message = Yard::Lint::Validators::Tags::CollectionType::MessagesBuilder.call(offense)

      end
  it 'call when enforcing long style short detected formats message for nested hash' do
      offense = {
        tag_name: 'return',
        type_string: 'Hash<String, Hash<Symbol, Integer>>',
        detected_style: 'short'
      }

      message = Yard::Lint::Validators::Tags::CollectionType::MessagesBuilder.call(offense)

      end
  it 'call when enforcing short style long detected formats message for hash k v to k v' do
      offense = {
        tag_name: 'param',
        type_string: 'Hash{Symbol => String}',
        detected_style: 'long'
      }

      message = Yard::Lint::Validators::Tags::CollectionType::MessagesBuilder.call(offense)

      end
  it 'call when enforcing short style long detected formats message for option tag' do
      offense = {
        tag_name: 'option',
        type_string: 'Hash{String => Object}',
        detected_style: 'long'
      }

      message = Yard::Lint::Validators::Tags::CollectionType::MessagesBuilder.call(offense)

      end
end


# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsCollectionTypeMessagesBuilderTest < Minitest::Test

  def test_call_when_enforcing_long_style_short_detected_formats_message_for_hash_k_v_to_hash_k_v
      offense = {
        tag_name: 'param',
        type_string: 'Hash<Symbol, String>',
        detected_style: 'short'
      }

      message = Yard::Lint::Validators::Tags::CollectionType::MessagesBuilder.call(offense)

      end
  def test_call_when_enforcing_long_style_short_detected_formats_message_for_k_v_to_hash_k_v
      offense = {
        tag_name: 'return',
        type_string: '{Symbol => String}',
        detected_style: 'short'
      }

      message = Yard::Lint::Validators::Tags::CollectionType::MessagesBuilder.call(offense)

      end
  def test_call_when_enforcing_long_style_short_detected_formats_message_for_nested_hash
      offense = {
        tag_name: 'return',
        type_string: 'Hash<String, Hash<Symbol, Integer>>',
        detected_style: 'short'
      }

      message = Yard::Lint::Validators::Tags::CollectionType::MessagesBuilder.call(offense)

      end
  def test_call_when_enforcing_short_style_long_detected_formats_message_for_hash_k_v_to_k_v
      offense = {
        tag_name: 'param',
        type_string: 'Hash{Symbol => String}',
        detected_style: 'long'
      }

      message = Yard::Lint::Validators::Tags::CollectionType::MessagesBuilder.call(offense)

      end
  def test_call_when_enforcing_short_style_long_detected_formats_message_for_option_tag
      offense = {
        tag_name: 'option',
        type_string: 'Hash{String => Object}',
        detected_style: 'long'
      }

      message = Yard::Lint::Validators::Tags::CollectionType::MessagesBuilder.call(offense)

      end
end


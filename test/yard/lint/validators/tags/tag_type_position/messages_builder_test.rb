# frozen_string_literal: true

require 'test_helper'

class YardLintValidatorsTagsTagTypePositionMessagesBuilderTest < Minitest::Test

  def test_call_when_enforcing_type_first_but_found_type_after_name_formats_message_correctly_for_param_ta
      offense = {
        tag_name: 'param',
        param_name: 'user',
        type_info: 'String',
        detected_style: 'type_after_name'
      }

      message = Yard::Lint::Validators::Tags::TagTypePosition::MessagesBuilder.call(offense)

      end
  def test_call_when_enforcing_type_first_but_found_type_after_name_formats_message_correctly_for_option_t
      offense = {
        tag_name: 'option',
        param_name: 'opts',
        type_info: 'Hash',
        detected_style: 'type_after_name'
      }

      message = Yard::Lint::Validators::Tags::TagTypePosition::MessagesBuilder.call(offense)

      end
  def test_call_when_enforcing_type_after_name_but_found_type_first_formats_message_correctly_for_param_ta
      offense = {
        tag_name: 'param',
        param_name: 'name',
        type_info: 'String',
        detected_style: 'type_first'
      }

      message = Yard::Lint::Validators::Tags::TagTypePosition::MessagesBuilder.call(offense)

      end
  def test_call_when_enforcing_type_after_name_but_found_type_first_formats_message_correctly_for_option_t
      offense = {
        tag_name: 'option',
        param_name: 'config',
        type_info: 'Hash{Symbol => Object}',
        detected_style: 'type_first'
      }

      message = Yard::Lint::Validators::Tags::TagTypePosition::MessagesBuilder.call(offense)

      end
  def test_call_with_complex_type_annotations_handles_nested_types_correctly
      offense = {
        tag_name: 'param',
        param_name: 'options',
        type_info: 'Hash{String => Array<Integer>}',
        detected_style: 'type_after_name'
      }

      message = Yard::Lint::Validators::Tags::TagTypePosition::MessagesBuilder.call(offense)

      end
end


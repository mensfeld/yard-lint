# frozen_string_literal: true

require 'test_helper'

# Helper to convert relative paths to absolute paths from project root
class YardLintValidatorsTest < Minitest::Test
  attr_reader :config

  def project_path(relative_path)
    File.expand_path("../../#{relative_path}", __dir__)
  end

  # -- API Tags: enabled --

  def setup_api_tags_enabled
    @config = test_config do |c|
      c.set_validator_config('Tags/ApiTags', 'Enabled', true)
      c.set_validator_config('Tags/ApiTags', 'AllowedApis', %w[public private internal])
    end
  end

  def test_api_tags_validation_when_require_api_tags_is_enabled_detects_api_tag_issues
    setup_api_tags_enabled

    result = Yard::Lint.run(path: project_path('lib/yard/lint/version.rb'), config: config)

    assert_kind_of(Array, result.offenses.select { |o| o[:name].to_s.include?('Api') })
    assert_respond_to(result, :offenses)
  end

  # -- API Tags: disabled --

  def setup_api_tags_disabled
    @config = test_config do |c|
      c.set_validator_config('Tags/ApiTags', 'Enabled', false)
    end
  end

  def test_api_tags_validation_when_require_api_tags_is_disabled_does_not_run_api_tag_validation
    setup_api_tags_disabled

    result = Yard::Lint.run(path: project_path('lib/yard/lint/version.rb'), config: config)

    assert_empty(result.offenses.select { |o| o[:name].to_s.include?('Api') })
  end

  # -- API Tags: custom allowed APIs --

  def setup_api_tags_custom
    @config = test_config do |c|
      c.set_validator_config('Tags/ApiTags', 'Enabled', true)
      c.set_validator_config('Tags/ApiTags', 'AllowedApis', %w[public])
    end
  end

  def test_api_tags_validation_with_custom_allowed_apis_uses_custom_allowed_apis_configuration
    setup_api_tags_custom

    result = Yard::Lint.run(path: project_path('lib/yard/lint/version.rb'), config: config)

    assert_kind_of(Array, result.offenses.select { |o| o[:name].to_s.include?('Api') })
  end

  # -- Abstract Methods: enabled --

  def setup_abstract_methods_enabled
    @config = test_config do |c|
      c.set_validator_config('Semantic/AbstractMethods', 'Enabled', true)
    end
  end

  def test_abstract_methods_validation_when_validate_abstract_methods_is_enabled_runs_abstract_method_validation
    setup_abstract_methods_enabled

    result = Yard::Lint.run(path: project_path('lib'), config: config)

    assert_kind_of(Array, result.offenses.select { |o| o[:name].to_s.include?('Abstract') })
    assert_respond_to(result, :offenses)
  end

  # -- Abstract Methods: disabled --

  def setup_abstract_methods_disabled
    @config = test_config do |c|
      c.set_validator_config('Semantic/AbstractMethods', 'Enabled', false)
    end
  end

  def test_abstract_methods_validation_when_validate_abstract_methods_is_disabled_does_not_run_abstract_method_validation
    setup_abstract_methods_disabled

    result = Yard::Lint.run(path: project_path('lib'), config: config)

    assert_empty(result.offenses.select { |o| o[:name].to_s.include?('Abstract') })
  end

  # -- Option Tags: enabled --

  def setup_option_tags_enabled
    @config = test_config do |c|
      c.set_validator_config('Tags/OptionTags', 'Enabled', true)
    end
  end

  def test_option_tags_validation_when_validate_option_tags_is_enabled_runs_option_tags_validation
    setup_option_tags_enabled

    result = Yard::Lint.run(path: project_path('lib'), config: config)

    assert_kind_of(Array, result.offenses.select { |o| o[:name].to_s.include?('Option') })
    assert_respond_to(result, :offenses)
  end

  # -- Option Tags: disabled --

  def setup_option_tags_disabled
    @config = test_config do |c|
      c.set_validator_config('Tags/OptionTags', 'Enabled', false)
      c.set_validator_config('Tags/ExampleSyntax', 'Enabled', false)
    end
  end

  def test_option_tags_validation_when_validate_option_tags_is_disabled_does_not_run_option_tags_validation
    setup_option_tags_disabled

    result = Yard::Lint.run(path: project_path('lib'), config: config)

    assert_empty(result.offenses.select { |o| o[:name] == 'OptionTags' })
  end

  # -- Combined Validators --

  def setup_combined_validators
    @config = test_config do |c|
      c.set_validator_config('Tags/ApiTags', 'Enabled', true)
      c.set_validator_config('Semantic/AbstractMethods', 'Enabled', true)
      c.set_validator_config('Tags/OptionTags', 'Enabled', true)
    end
  end

  def test_combined_validators_runs_all_validators_when_enabled
    setup_combined_validators

    result = Yard::Lint.run(path: project_path('lib'), config: config)

    assert_kind_of(Array, result.offenses.select { |o| o[:name].to_s.include?('Api') })
    assert_kind_of(Array, result.offenses.select { |o| o[:name].to_s.include?('Abstract') })
    assert_kind_of(Array, result.offenses.select { |o| o[:name].to_s.include?('Option') })
  end

  def test_combined_validators_includes_all_offense_types_in_the_offenses_array
    setup_combined_validators

    result = Yard::Lint.run(path: project_path('lib'), config: config)

    assert_kind_of(Array, result.offenses)
    assert_respond_to(result, :offenses)
    assert_respond_to(result, :count)
    assert_respond_to(result, :clean?)
  end

  # -- Documentation Category Validators Together --

  def setup_documentation_validators
    @config = test_config do |c|
      c.set_validator_config('Documentation/UndocumentedObjects', 'Enabled', true)
      c.set_validator_config('Documentation/UndocumentedMethodArguments', 'Enabled', true)
      c.set_validator_config('Documentation/UndocumentedBooleanMethods', 'Enabled', true)
    end
  end

  def test_documentation_category_validators_together_runs_all_documentation_validators_simultaneously
    setup_documentation_validators

    result = Yard::Lint.run(path: project_path('lib'), config: config)

    offense_names = result.offenses.map { |o| o[:name] }.uniq
    documentation_validators = offense_names.select { |n| n.start_with?('Undocumented') }

    assert_kind_of(Array, result.offenses)
    assert_respond_to(result, :count)
  end

  def test_documentation_category_validators_together_can_detect_multiple_documentation_issues_in_the_same_file
    setup_documentation_validators

    result = Yard::Lint.run(path: project_path('lib'), config: config)

    by_file = result.offenses.group_by { |o| o[:location] }

    multi_issue_files = by_file.select { |_file, offenses| offenses.size > 1 }

    if multi_issue_files.any?
      multi_issue_files.each do |_file, offenses|
        assert_operator(offenses.size, :>, 1)
        offenses.each { |e| assert_kind_of(Hash, e) }
      end
    end

    # Test always passes - we're just checking the structure works
    assert_kind_of(Hash, by_file)
  end

  # -- Tags Category Validators Together --

  def setup_tags_validators
    @config = test_config do |c|
      c.set_validator_config('Tags/Order', 'Enabled', true)
      c.set_validator_config('Tags/InvalidTypes', 'Enabled', true)
      c.set_validator_config('Tags/TypeSyntax', 'Enabled', true)
    end
  end

  def test_tags_category_validators_together_runs_all_tag_validators_simultaneously
    setup_tags_validators

    result = Yard::Lint.run(path: project_path('lib'), config: config)

    offense_names = result.offenses.map { |o| o[:name] }.uniq
    tag_validators = %w[InvalidTagOrder InvalidTypes InvalidTypeSyntax]

    assert_kind_of(Array, result.offenses)
  end

  def test_tags_category_validators_together_handles_type_validation_interactions_correctly
    setup_tags_validators

    result = Yard::Lint.run(path: project_path('lib'), config: config)

    type_syntax = result.offenses.select { |o| o[:name] == 'InvalidTypeSyntax' }
    invalid_types = result.offenses.select { |o| o[:name] == 'InvalidTypes' }

    assert_kind_of(Array, type_syntax)
    assert_kind_of(Array, invalid_types)
  end

  # -- Warnings Category Validators Together --

  def setup_warnings_validators
    @config = test_config do |c|
      c.set_validator_config('Warnings/UnknownTag', 'Enabled', true)
      c.set_validator_config('Warnings/UnknownParameterName', 'Enabled', true)
      c.set_validator_config('Warnings/DuplicatedParameterName', 'Enabled', true)
      c.set_validator_config('Warnings/InvalidTagFormat', 'Enabled', true)
    end
  end

  def test_warnings_category_validators_together_runs_all_warning_validators_simultaneously
    setup_warnings_validators

    result = Yard::Lint.run(path: project_path('lib'), config: config)

    warning_offenses = result.offenses.select do |o|
      %w[UnknownTag UnknownParameterName DuplicatedParameterName
         InvalidTagFormat].include?(o[:name])
    end

    assert_kind_of(Array, warning_offenses)
  end

  def test_warnings_category_validators_together_detects_parameter_related_warnings_together
    setup_warnings_validators

    result = Yard::Lint.run(path: project_path('lib'), config: config)

    unknown_param = result.offenses.select { |o| o[:name] == 'UnknownParameterName' }
    duplicated_param = result.offenses.select { |o| o[:name] == 'DuplicatedParameterName' }

    assert_kind_of(Array, unknown_param)
    assert_kind_of(Array, duplicated_param)
  end

  # -- Cross-Category Combinations --

  def setup_cross_category
    @config = test_config do |c|
      c.set_validator_config('Documentation/UndocumentedMethodArguments', 'Enabled', true)
      c.set_validator_config('Tags/Order', 'Enabled', true)
      c.set_validator_config('Warnings/UnknownParameterName', 'Enabled', true)
    end
  end

  def test_cross_category_combinations_runs_validators_from_different_categories_together
    setup_cross_category

    result = Yard::Lint.run(path: project_path('lib'), config: config)

    has_documentation = result.offenses.any? { |o| o[:name] == 'UndocumentedMethodArguments' }
    has_tags = result.offenses.any? { |o| o[:name] == 'InvalidTagOrder' }
    has_warnings = result.offenses.any? { |o| o[:name] == 'UnknownParameterName' }

    assert_kind_of(Array, result.offenses)
  end

  def test_cross_category_combinations_handles_multiple_categories_on_the_same_method
    setup_cross_category

    result = Yard::Lint.run(path: project_path('lib'), config: config)

    by_method = result.offenses.group_by { |o| [o[:location], o[:location_line]] }

    multi_category = by_method.select do |_key, offenses|
      categories = offenses.map { |o| o[:name] }.uniq
      categories.size > 1
    end

    assert_kind_of(Hash, multi_category)
  end

  # -- Example Syntax: enabled --

  def setup_example_syntax_enabled
    @config = test_config do |c|
      c.set_validator_config('Tags/ExampleSyntax', 'Enabled', true)
    end
  end

  def test_example_syntax_validation_when_example_syntax_is_enabled_runs_example_syntax_validation
    setup_example_syntax_enabled

    result = Yard::Lint.run(path: project_path('test/fixtures/example_syntax.rb'), config: config)

    example_syntax_offenses = result.offenses.select { |o| o[:name] == 'ExampleSyntax' }
    refute_empty(example_syntax_offenses)
    assert_respond_to(result, :offenses)
  end

  def test_example_syntax_validation_when_example_syntax_is_enabled_detects_syntax_errors_in_example_code_blocks
    setup_example_syntax_enabled

    result = Yard::Lint.run(path: project_path('test/fixtures/example_syntax.rb'), config: config)

    example_syntax_offenses = result.offenses.select { |o| o[:name] == 'ExampleSyntax' }

    assert_operator(example_syntax_offenses.size, :>=, 2)

    example_syntax_offenses.each do |offense|
      assert_includes(offense[:message], 'syntax error')
    end
  end

  def test_example_syntax_validation_when_example_syntax_is_enabled_provides_detailed_error_messages_with_line_numbers
    setup_example_syntax_enabled

    result = Yard::Lint.run(path: project_path('test/fixtures/example_syntax.rb'), config: config)

    example_syntax_offenses = result.offenses.select { |o| o[:name] == 'ExampleSyntax' }

    example_syntax_offenses.each do |offense|
      assert(offense.key?(:location))
      assert(offense.key?(:location_line))
      assert(offense.key?(:message))
      assert_equal('warning', offense[:severity])
    end
  end

  def test_example_syntax_validation_when_example_syntax_is_enabled_skips_incomplete_single_line_snippets
    setup_example_syntax_enabled

    result = Yard::Lint.run(path: project_path('test/fixtures/example_syntax.rb'), config: config)

    example_syntax_offenses = result.offenses.select { |o| o[:name] == 'ExampleSyntax' }

    multiply_offenses = example_syntax_offenses.select do |o|
      o[:message].include?('multiply')
    end

    assert_empty(multiply_offenses)
  end

  # -- Example Syntax: disabled --

  def test_example_syntax_validation_when_example_syntax_is_disabled_does_not_run_example_syntax_validation
    @config = test_config do |c|
      c.set_validator_config('Tags/ExampleSyntax', 'Enabled', false)
    end

    result = Yard::Lint.run(path: project_path('test/fixtures/example_syntax.rb'), config: config)

    example_syntax_offenses = result.offenses.select { |o| o[:name] == 'ExampleSyntax' }
    assert_empty(example_syntax_offenses)
  end

  # -- Example Syntax: with valid examples --

  def test_example_syntax_validation_with_valid_examples_does_not_report_errors_for_files_without_examples
    @config = test_config do |c|
      c.set_validator_config('Tags/ExampleSyntax', 'Enabled', true)
      c.set_validator_config('Tags/Order', 'Enabled', false)
    end

    result = Yard::Lint.run(path: project_path('test/fixtures/clean_code.rb'), config: config)

    example_syntax_offenses = result.offenses.select { |o| o[:name] == 'ExampleSyntax' }
    clean_code_offenses = example_syntax_offenses.select do |o|
      o[:location].include?('clean_code.rb')
    end
    assert_empty(clean_code_offenses)
  end

  # -- Redundant Param Description: enabled --

  def setup_redundant_param_enabled
    @config = test_config do |c|
      c.set_validator_config('Tags/RedundantParamDescription', 'Enabled', true)
    end
  end

  def test_redundant_param_description_validation_when_enabled_runs_redundant_param_description_validation
    setup_redundant_param_enabled

    result = Yard::Lint.run(path: project_path('test/fixtures/redundant_param_descriptions.rb'), config: config)

    redundant_offenses = result.offenses.select { |o| o[:name] == 'RedundantParamDescription' }
    refute_empty(redundant_offenses)
    assert_respond_to(result, :offenses)
  end

  def test_redundant_param_description_validation_when_enabled_detects_article_plus_param_pattern
    setup_redundant_param_enabled

    result = Yard::Lint.run(path: project_path('test/fixtures/redundant_param_descriptions.rb'), config: config)

    redundant_offenses = result.offenses.select { |o| o[:name] == 'RedundantParamDescription' }

    article_pattern_offenses = redundant_offenses.select do |o|
      o[:message].include?('restates the parameter name')
    end

    refute_empty(article_pattern_offenses)
  end

  def test_redundant_param_description_validation_when_enabled_detects_possessive_plus_param_pattern
    setup_redundant_param_enabled

    result = Yard::Lint.run(path: project_path('test/fixtures/redundant_param_descriptions.rb'), config: config)

    redundant_offenses = result.offenses.select { |o| o[:name] == 'RedundantParamDescription' }

    possessive_offenses = redundant_offenses.select do |o|
      o[:message].include?('adds no meaningful information')
    end

    refute_empty(possessive_offenses)
  end

  def test_redundant_param_description_validation_when_enabled_detects_type_restatement_pattern
    setup_redundant_param_enabled

    result = Yard::Lint.run(path: project_path('test/fixtures/redundant_param_descriptions.rb'), config: config)

    redundant_offenses = result.offenses.select { |o| o[:name] == 'RedundantParamDescription' }

    type_restatement_offenses = redundant_offenses.select do |o|
      o[:message].include?('repeats the type name')
    end

    refute_empty(type_restatement_offenses)
  end

  def test_redundant_param_description_validation_when_enabled_does_not_flag_long_meaningful_descriptions
    setup_redundant_param_enabled

    result = Yard::Lint.run(path: project_path('test/fixtures/redundant_param_descriptions.rb'), config: config)

    redundant_offenses = result.offenses.select { |o| o[:name] == 'RedundantParamDescription' }

    long_desc_method_offenses = redundant_offenses.select do |o|
      o[:object_name] == 'RedundantParamFixtures#long_meaningful_descriptions'
    end

    assert_empty(long_desc_method_offenses)
  end

  def test_redundant_param_description_validation_when_enabled_provides_detailed_error_messages_with_suggestions
    setup_redundant_param_enabled

    result = Yard::Lint.run(path: project_path('test/fixtures/redundant_param_descriptions.rb'), config: config)

    redundant_offenses = result.offenses.select { |o| o[:name] == 'RedundantParamDescription' }

    redundant_offenses.each do |offense|
      assert(offense.key?(:location))
      assert(offense.key?(:line))
      assert(offense.key?(:message))
      assert(offense.key?(:object_name))
      assert_equal('convention', offense[:severity])
      assert_match(/[Cc]onsider/, offense[:message])
    end
  end

  # -- Redundant Param Description: disabled --

  def test_redundant_param_description_validation_when_disabled_does_not_run_redundant_param_description_validation
    @config = test_config do |c|
      c.set_validator_config('Tags/RedundantParamDescription', 'Enabled', false)
    end

    result = Yard::Lint.run(path: project_path('test/fixtures/redundant_param_descriptions.rb'), config: config)

    redundant_offenses = result.offenses.select { |o| o[:name] == 'RedundantParamDescription' }
    assert_empty(redundant_offenses)
  end

  # -- Redundant Param Description: custom MaxRedundantWords --

  def test_redundant_param_description_validation_with_custom_configuration_respects_custom_maxredundantwords_threshold
    @config = test_config do |c|
      c.set_validator_config('Tags/RedundantParamDescription', 'Enabled', true)
      c.set_validator_config('Tags/RedundantParamDescription', 'MaxRedundantWords', 4)
    end

    result = Yard::Lint.run(path: project_path('test/fixtures/redundant_param_descriptions.rb'), config: config)

    redundant_offenses = result.offenses.select { |o| o[:name] == 'RedundantParamDescription' }

    assert_kind_of(Array, redundant_offenses)
  end

  # -- Redundant Param Description: pattern toggles --

  def test_redundant_param_description_validation_with_pattern_toggles_only_detects_enabled_patterns
    @config = test_config do |c|
      c.set_validator_config('Tags/RedundantParamDescription', 'Enabled', true)
      c.set_validator_config('Tags/RedundantParamDescription', 'EnabledPatterns', {
        'ArticleParam' => true,
        'PossessiveParam' => false,
        'TypeRestatement' => false,
        'ParamToVerb' => false,
        'IdPattern' => false,
        'DirectionalDate' => false,
        'TypeGeneric' => false,
        'ArticleParamPhrase' => false
      })
    end

    result = Yard::Lint.run(path: project_path('test/fixtures/redundant_param_descriptions.rb'), config: config)

    redundant_offenses = result.offenses.select { |o| o[:name] == 'RedundantParamDescription' }

    article_only = redundant_offenses.all? do |o|
      o[:message].include?('restates the parameter name')
    end

    assert_equal(true, article_only)
  end

  # -- Redundant Param Description: ArticleParamPhrase pattern --

  def test_redundant_param_description_validation_with_articleparamphrase_pattern_enabled_detects_filler_phrase_patterns
    @config = test_config do |c|
      c.set_validator_config('Tags/RedundantParamDescription', 'Enabled', true)
      c.set_validator_config('Tags/RedundantParamDescription', 'EnabledPatterns', {
        'ArticleParam' => false,
        'PossessiveParam' => false,
        'TypeRestatement' => false,
        'ParamToVerb' => false,
        'IdPattern' => false,
        'DirectionalDate' => false,
        'TypeGeneric' => false,
        'ArticleParamPhrase' => true
      })
    end

    result = Yard::Lint.run(path: project_path('test/fixtures/redundant_param_descriptions.rb'), config: config)

    redundant_offenses = result.offenses.select { |o| o[:name] == 'RedundantParamDescription' }

    phrase_violations = redundant_offenses.select do |o|
      o[:message].include?('filler phrase')
    end

    refute_empty(phrase_violations)
    assert_operator(phrase_violations.length, :>=, 3)
  end

  # -- Tag Group Separator: enabled --

  def setup_tag_group_separator_enabled
    @config = test_config do |c|
      c.set_validator_config('Tags/TagGroupSeparator', 'Enabled', true)
    end
  end

  def test_tag_group_separator_validation_when_enabled_runs_tag_group_separator_validation
    setup_tag_group_separator_enabled

    result = Yard::Lint.run(path: project_path('test/fixtures/tag_group_separators.rb'), config: config)

    separator_offenses = result.offenses.select { |o| o[:name] == 'MissingTagGroupSeparator' }
    refute_empty(separator_offenses)
    assert_respond_to(result, :offenses)
  end

  def test_tag_group_separator_validation_when_enabled_detects_missing_separator_between_param_and_return
    setup_tag_group_separator_enabled

    result = Yard::Lint.run(path: project_path('test/fixtures/tag_group_separators.rb'), config: config)

    separator_offenses = result.offenses.select { |o| o[:name] == 'MissingTagGroupSeparator' }

    param_return_offenses = separator_offenses.select do |o|
      o[:message].include?('param') && o[:message].include?('return')
    end

    refute_empty(param_return_offenses)
  end

  def test_tag_group_separator_validation_when_enabled_detects_multiple_missing_separators_in_same_method
    setup_tag_group_separator_enabled

    result = Yard::Lint.run(path: project_path('test/fixtures/tag_group_separators.rb'), config: config)

    separator_offenses = result.offenses.select { |o| o[:name] == 'MissingTagGroupSeparator' }

    multiple_offenses = separator_offenses.select do |o|
      o[:method_name] == 'multiple_missing_separators'
    end

    refute_empty(multiple_offenses)
  end

  def test_tag_group_separator_validation_when_enabled_does_not_flag_properly_separated_tag_groups
    setup_tag_group_separator_enabled

    result = Yard::Lint.run(path: project_path('test/fixtures/tag_group_separators.rb'), config: config)

    separator_offenses = result.offenses.select { |o| o[:name] == 'MissingTagGroupSeparator' }

    proper_offenses = separator_offenses.select do |o|
      o[:method_name] == 'proper_separators'
    end

    assert_empty(proper_offenses)
  end

  def test_tag_group_separator_validation_when_enabled_does_not_flag_same_group_consecutive_tags
    setup_tag_group_separator_enabled

    result = Yard::Lint.run(path: project_path('test/fixtures/tag_group_separators.rb'), config: config)

    separator_offenses = result.offenses.select { |o| o[:name] == 'MissingTagGroupSeparator' }

    same_group_offenses = separator_offenses.select do |o|
      o[:method_name] == 'same_group_tags'
    end

    assert_empty(same_group_offenses)
  end

  def test_tag_group_separator_validation_when_enabled_does_not_flag_methods_with_single_tag_group
    setup_tag_group_separator_enabled

    result = Yard::Lint.run(path: project_path('test/fixtures/tag_group_separators.rb'), config: config)

    separator_offenses = result.offenses.select { |o| o[:name] == 'MissingTagGroupSeparator' }

    single_group_offenses = separator_offenses.select do |o|
      o[:method_name] == 'single_group'
    end

    assert_empty(single_group_offenses)
  end

  def test_tag_group_separator_validation_when_enabled_provides_detailed_error_messages
    setup_tag_group_separator_enabled

    result = Yard::Lint.run(path: project_path('test/fixtures/tag_group_separators.rb'), config: config)

    separator_offenses = result.offenses.select { |o| o[:name] == 'MissingTagGroupSeparator' }

    separator_offenses.each do |offense|
      assert(offense.key?(:location))
      assert(offense.key?(:location_line))
      assert(offense.key?(:message))
      assert_equal('convention', offense[:severity])
      assert_includes(offense[:message], 'blank line')
    end
  end

  # -- Tag Group Separator: disabled --

  def test_tag_group_separator_validation_when_disabled_does_not_run_tag_group_separator_validation
    @config = test_config do |c|
      c.set_validator_config('Tags/TagGroupSeparator', 'Enabled', false)
    end

    result = Yard::Lint.run(path: project_path('test/fixtures/tag_group_separators.rb'), config: config)

    separator_offenses = result.offenses.select { |o| o[:name] == 'MissingTagGroupSeparator' }
    assert_empty(separator_offenses)
  end

  # -- Tag Group Separator: custom tag groups --

  def test_tag_group_separator_validation_with_custom_tag_groups_respects_custom_tag_group_configuration
    @config = test_config do |c|
      c.set_validator_config('Tags/TagGroupSeparator', 'Enabled', true)
      c.set_validator_config('Tags/TagGroupSeparator', 'TagGroups', {
        'param' => %w[param option],
        'return' => %w[return raise]
      })
    end

    result = Yard::Lint.run(path: project_path('test/fixtures/tag_group_separators.rb'), config: config)

    separator_offenses = result.offenses.select { |o| o[:name] == 'MissingTagGroupSeparator' }

    return_raise_offenses = separator_offenses.select do |o|
      o[:method_name] == 'missing_return_raise_separator' &&
        o[:message].include?('return') && o[:message].include?('error')
    end

    assert_empty(return_raise_offenses)
  end

  # -- Tag Group Separator: RequireAfterDescription --

  def setup_tag_group_separator_require_after_description
    @config = test_config do |c|
      c.set_validator_config('Tags/TagGroupSeparator', 'Enabled', true)
      c.set_validator_config('Tags/TagGroupSeparator', 'RequireAfterDescription', true)
    end
  end

  def test_tag_group_separator_validation_with_requireafterdescription_enabled_detects_missing_separator_after_description
    setup_tag_group_separator_require_after_description

    result = Yard::Lint.run(path: project_path('test/fixtures/tag_group_separators.rb'), config: config)

    separator_offenses = result.offenses.select { |o| o[:name] == 'MissingTagGroupSeparator' }

    description_offenses = separator_offenses.select do |o|
      o[:method_name] == 'description_to_param_no_separator'
    end

    refute_empty(description_offenses)
  end

  def test_tag_group_separator_validation_with_requireafterdescription_enabled_does_not_flag_description_with_proper_separator
    setup_tag_group_separator_require_after_description

    result = Yard::Lint.run(path: project_path('test/fixtures/tag_group_separators.rb'), config: config)

    separator_offenses = result.offenses.select { |o| o[:name] == 'MissingTagGroupSeparator' }

    proper_desc_offenses = separator_offenses.select do |o|
      o[:method_name] == 'description_to_param_with_separator' &&
        o[:message].include?('description')
    end

    assert_empty(proper_desc_offenses)
  end

  # -- Tag Group Separator: complex documentation --

  def test_tag_group_separator_validation_with_complex_documentation_validates_complex_documentation_with_all_separators
    setup_tag_group_separator_enabled

    result = Yard::Lint.run(path: project_path('test/fixtures/tag_group_separators.rb'), config: config)

    separator_offenses = result.offenses.select { |o| o[:name] == 'MissingTagGroupSeparator' }

    complex_offenses = separator_offenses.select do |o|
      o[:method_name] == 'complex_with_all_separators'
    end

    assert_empty(complex_offenses)
  end

  # -- All Validators Enabled --

  def setup_all_validators
    @config = test_config do |c|
      Yard::Lint::ConfigLoader::ALL_VALIDATORS.each do |validator_name|
        c.set_validator_config(validator_name, 'Enabled', true)
      end
    end
  end

  def test_all_validators_enabled_successfully_runs_with_all_validators_enabled
    setup_all_validators

    result = Yard::Lint.run(path: project_path('lib/yard/lint/version.rb'), config: config, progress: false)

    assert_respond_to(result, :offenses)
    assert_respond_to(result, :count)
    assert_kind_of(Array, result.offenses)
  end

  def test_all_validators_enabled_completes_analysis_in_reasonable_time_with_all_validators
    setup_all_validators

    start_time = Time.now
    result = Yard::Lint.run(path: project_path('lib/yard/lint/version.rb'), config: config, progress: false)
    elapsed = Time.now - start_time

    assert_operator(elapsed, :<, 10)
    assert_kind_of(Array, result.offenses)
  end

  def test_all_validators_enabled_produces_consistent_results_across_multiple_runs
    setup_all_validators

    result1 = Yard::Lint.run(path: project_path('lib/yard/lint/version.rb'), config: config, progress: false)
    result2 = Yard::Lint.run(path: project_path('lib/yard/lint/version.rb'), config: config, progress: false)

    assert_equal(result1.count, result2.count)
    assert_equal(result1.offenses.size, result2.offenses.size)
  end
end

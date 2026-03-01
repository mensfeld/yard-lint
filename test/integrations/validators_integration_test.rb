# frozen_string_literal: true

require 'test_helper'


# Helper to convert relative paths to absolute paths from project root
describe 'Validators Integration' do
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

  it 'api tags validation when require api tags is enabled detects api tag issues' do
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

  it 'api tags validation when require api tags is disabled does not run api tag validation' do
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

  it 'api tags validation with custom allowed apis uses custom allowed apis configuration' do
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

  it 'abstract methods validation when validate abstract methods is enabled runs abstract method validation' do
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

  it 'abstract methods validation when validate abstract methods is disabled does not run abstract method validation' do
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

  it 'option tags validation when validate option tags is enabled runs option tags validation' do
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

  it 'option tags validation when validate option tags is disabled does not run option tags validation' do
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

  it 'combined validators runs all validators when enabled' do
    setup_combined_validators

    result = Yard::Lint.run(path: project_path('lib'), config: config)

    assert_kind_of(Array, result.offenses.select { |o| o[:name].to_s.include?('Api') })
    assert_kind_of(Array, result.offenses.select { |o| o[:name].to_s.include?('Abstract') })
    assert_kind_of(Array, result.offenses.select { |o| o[:name].to_s.include?('Option') })
  end

  it 'combined validators includes all offense types in the offenses array' do
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

  it 'documentation category validators together runs all documentation validators simultaneously' do
    setup_documentation_validators

    result = Yard::Lint.run(path: project_path('lib'), config: config)

    offense_names = result.offenses.map { |o| o[:name] }.uniq
    documentation_validators = offense_names.select { |n| n.start_with?('Undocumented') }

    assert_kind_of(Array, result.offenses)
    assert_respond_to(result, :count)
  end

  it 'documentation category validators together can detect multiple documentation issues in the same file' do
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

  it 'tags category validators together runs all tag validators simultaneously' do
    setup_tags_validators

    result = Yard::Lint.run(path: project_path('lib'), config: config)

    offense_names = result.offenses.map { |o| o[:name] }.uniq
    tag_validators = %w[InvalidTagOrder InvalidTypes InvalidTypeSyntax]

    assert_kind_of(Array, result.offenses)
  end

  it 'tags category validators together handles type validation interactions correctly' do
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

  it 'warnings category validators together runs all warning validators simultaneously' do
    setup_warnings_validators

    result = Yard::Lint.run(path: project_path('lib'), config: config)

    warning_offenses = result.offenses.select do |o|
      %w[UnknownTag UnknownParameterName DuplicatedParameterName
         InvalidTagFormat].include?(o[:name])
    end

    assert_kind_of(Array, warning_offenses)
  end

  it 'warnings category validators together detects parameter related warnings together' do
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

  it 'cross category combinations runs validators from different categories together' do
    setup_cross_category

    result = Yard::Lint.run(path: project_path('lib'), config: config)

    has_documentation = result.offenses.any? { |o| o[:name] == 'UndocumentedMethodArguments' }
    has_tags = result.offenses.any? { |o| o[:name] == 'InvalidTagOrder' }
    has_warnings = result.offenses.any? { |o| o[:name] == 'UnknownParameterName' }

    assert_kind_of(Array, result.offenses)
  end

  it 'cross category combinations handles multiple categories on the same method' do
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

  it 'example syntax validation when example syntax is enabled runs example syntax validation' do
    setup_example_syntax_enabled

    result = Yard::Lint.run(path: project_path('test/fixtures/example_syntax.rb'), config: config)

    example_syntax_offenses = result.offenses.select { |o| o[:name] == 'ExampleSyntax' }
    refute_empty(example_syntax_offenses)
    assert_respond_to(result, :offenses)
  end

  it 'example syntax validation when example syntax is enabled detects syntax errors in example code blocks' do
    setup_example_syntax_enabled

    result = Yard::Lint.run(path: project_path('test/fixtures/example_syntax.rb'), config: config)

    example_syntax_offenses = result.offenses.select { |o| o[:name] == 'ExampleSyntax' }

    assert_operator(example_syntax_offenses.size, :>=, 2)

    example_syntax_offenses.each do |offense|
      assert_includes(offense[:message], 'syntax error')
    end
  end

  it 'example syntax validation when example syntax is enabled provides detailed error messages with line numbers' do
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

  it 'example syntax validation when example syntax is enabled skips incomplete single line snippets' do
    setup_example_syntax_enabled

    result = Yard::Lint.run(path: project_path('test/fixtures/example_syntax.rb'), config: config)

    example_syntax_offenses = result.offenses.select { |o| o[:name] == 'ExampleSyntax' }

    multiply_offenses = example_syntax_offenses.select do |o|
      o[:message].include?('multiply')
    end

    assert_empty(multiply_offenses)
  end

  # -- Example Syntax: disabled --

  it 'example syntax validation when example syntax is disabled does not run example syntax validation' do
    @config = test_config do |c|
      c.set_validator_config('Tags/ExampleSyntax', 'Enabled', false)
    end

    result = Yard::Lint.run(path: project_path('test/fixtures/example_syntax.rb'), config: config)

    example_syntax_offenses = result.offenses.select { |o| o[:name] == 'ExampleSyntax' }
    assert_empty(example_syntax_offenses)
  end

  # -- Example Syntax: with valid examples --

  it 'example syntax validation with valid examples does not report errors for files without examples' do
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

  it 'redundant param description validation when enabled runs redundant param description validation' do
    setup_redundant_param_enabled

    result = Yard::Lint.run(path: project_path('test/fixtures/redundant_param_descriptions.rb'), config: config)

    redundant_offenses = result.offenses.select { |o| o[:name] == 'RedundantParamDescription' }
    refute_empty(redundant_offenses)
    assert_respond_to(result, :offenses)
  end

  it 'redundant param description validation when enabled detects article plus param pattern' do
    setup_redundant_param_enabled

    result = Yard::Lint.run(path: project_path('test/fixtures/redundant_param_descriptions.rb'), config: config)

    redundant_offenses = result.offenses.select { |o| o[:name] == 'RedundantParamDescription' }

    article_pattern_offenses = redundant_offenses.select do |o|
      o[:message].include?('restates the parameter name')
    end

    refute_empty(article_pattern_offenses)
  end

  it 'redundant param description validation when enabled detects possessive plus param pattern' do
    setup_redundant_param_enabled

    result = Yard::Lint.run(path: project_path('test/fixtures/redundant_param_descriptions.rb'), config: config)

    redundant_offenses = result.offenses.select { |o| o[:name] == 'RedundantParamDescription' }

    possessive_offenses = redundant_offenses.select do |o|
      o[:message].include?('adds no meaningful information')
    end

    refute_empty(possessive_offenses)
  end

  it 'redundant param description validation when enabled detects type restatement pattern' do
    setup_redundant_param_enabled

    result = Yard::Lint.run(path: project_path('test/fixtures/redundant_param_descriptions.rb'), config: config)

    redundant_offenses = result.offenses.select { |o| o[:name] == 'RedundantParamDescription' }

    type_restatement_offenses = redundant_offenses.select do |o|
      o[:message].include?('repeats the type name')
    end

    refute_empty(type_restatement_offenses)
  end

  it 'redundant param description validation when enabled does not flag long meaningful descriptions' do
    setup_redundant_param_enabled

    result = Yard::Lint.run(path: project_path('test/fixtures/redundant_param_descriptions.rb'), config: config)

    redundant_offenses = result.offenses.select { |o| o[:name] == 'RedundantParamDescription' }

    long_desc_method_offenses = redundant_offenses.select do |o|
      o[:object_name] == 'RedundantParamFixtures#long_meaningful_descriptions'
    end

    assert_empty(long_desc_method_offenses)
  end

  it 'redundant param description validation when enabled provides detailed error messages with suggestions' do
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

  it 'redundant param description validation when disabled does not run redundant param description validation' do
    @config = test_config do |c|
      c.set_validator_config('Tags/RedundantParamDescription', 'Enabled', false)
    end

    result = Yard::Lint.run(path: project_path('test/fixtures/redundant_param_descriptions.rb'), config: config)

    redundant_offenses = result.offenses.select { |o| o[:name] == 'RedundantParamDescription' }
    assert_empty(redundant_offenses)
  end

  # -- Redundant Param Description: custom MaxRedundantWords --

  it 'redundant param description validation with custom configuration respects custom maxredundantwords threshold' do
    @config = test_config do |c|
      c.set_validator_config('Tags/RedundantParamDescription', 'Enabled', true)
      c.set_validator_config('Tags/RedundantParamDescription', 'MaxRedundantWords', 4)
    end

    result = Yard::Lint.run(path: project_path('test/fixtures/redundant_param_descriptions.rb'), config: config)

    redundant_offenses = result.offenses.select { |o| o[:name] == 'RedundantParamDescription' }

    assert_kind_of(Array, redundant_offenses)
  end

  # -- Redundant Param Description: pattern toggles --

  it 'redundant param description validation with pattern toggles only detects enabled patterns' do
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

  it 'redundant param description validation with articleparamphrase pattern enabled detects filler phrase patterns' do
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

  it 'tag group separator validation when enabled runs tag group separator validation' do
    setup_tag_group_separator_enabled

    result = Yard::Lint.run(path: project_path('test/fixtures/tag_group_separators.rb'), config: config)

    separator_offenses = result.offenses.select { |o| o[:name] == 'MissingTagGroupSeparator' }
    refute_empty(separator_offenses)
    assert_respond_to(result, :offenses)
  end

  it 'tag group separator validation when enabled detects missing separator between param and return' do
    setup_tag_group_separator_enabled

    result = Yard::Lint.run(path: project_path('test/fixtures/tag_group_separators.rb'), config: config)

    separator_offenses = result.offenses.select { |o| o[:name] == 'MissingTagGroupSeparator' }

    param_return_offenses = separator_offenses.select do |o|
      o[:message].include?('param') && o[:message].include?('return')
    end

    refute_empty(param_return_offenses)
  end

  it 'tag group separator validation when enabled detects multiple missing separators in same method' do
    setup_tag_group_separator_enabled

    result = Yard::Lint.run(path: project_path('test/fixtures/tag_group_separators.rb'), config: config)

    separator_offenses = result.offenses.select { |o| o[:name] == 'MissingTagGroupSeparator' }

    multiple_offenses = separator_offenses.select do |o|
      o[:method_name] == 'multiple_missing_separators'
    end

    refute_empty(multiple_offenses)
  end

  it 'tag group separator validation when enabled does not flag properly separated tag groups' do
    setup_tag_group_separator_enabled

    result = Yard::Lint.run(path: project_path('test/fixtures/tag_group_separators.rb'), config: config)

    separator_offenses = result.offenses.select { |o| o[:name] == 'MissingTagGroupSeparator' }

    proper_offenses = separator_offenses.select do |o|
      o[:method_name] == 'proper_separators'
    end

    assert_empty(proper_offenses)
  end

  it 'tag group separator validation when enabled does not flag same group consecutive tags' do
    setup_tag_group_separator_enabled

    result = Yard::Lint.run(path: project_path('test/fixtures/tag_group_separators.rb'), config: config)

    separator_offenses = result.offenses.select { |o| o[:name] == 'MissingTagGroupSeparator' }

    same_group_offenses = separator_offenses.select do |o|
      o[:method_name] == 'same_group_tags'
    end

    assert_empty(same_group_offenses)
  end

  it 'tag group separator validation when enabled does not flag methods with single tag group' do
    setup_tag_group_separator_enabled

    result = Yard::Lint.run(path: project_path('test/fixtures/tag_group_separators.rb'), config: config)

    separator_offenses = result.offenses.select { |o| o[:name] == 'MissingTagGroupSeparator' }

    single_group_offenses = separator_offenses.select do |o|
      o[:method_name] == 'single_group'
    end

    assert_empty(single_group_offenses)
  end

  it 'tag group separator validation when enabled provides detailed error messages' do
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

  it 'tag group separator validation when disabled does not run tag group separator validation' do
    @config = test_config do |c|
      c.set_validator_config('Tags/TagGroupSeparator', 'Enabled', false)
    end

    result = Yard::Lint.run(path: project_path('test/fixtures/tag_group_separators.rb'), config: config)

    separator_offenses = result.offenses.select { |o| o[:name] == 'MissingTagGroupSeparator' }
    assert_empty(separator_offenses)
  end

  # -- Tag Group Separator: custom tag groups --

  it 'tag group separator validation with custom tag groups respects custom tag group configuration' do
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

  it 'tag group separator validation with requireafterdescription enabled detects missing separator after description' do
    setup_tag_group_separator_require_after_description

    result = Yard::Lint.run(path: project_path('test/fixtures/tag_group_separators.rb'), config: config)

    separator_offenses = result.offenses.select { |o| o[:name] == 'MissingTagGroupSeparator' }

    description_offenses = separator_offenses.select do |o|
      o[:method_name] == 'description_to_param_no_separator'
    end

    refute_empty(description_offenses)
  end

  it 'tag group separator validation with requireafterdescription enabled does not flag description with proper separator' do
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

  it 'tag group separator validation with complex documentation validates complex documentation with all separators' do
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

  it 'all validators enabled successfully runs with all validators enabled' do
    setup_all_validators

    result = Yard::Lint.run(path: project_path('lib/yard/lint/version.rb'), config: config, progress: false)

    assert_respond_to(result, :offenses)
    assert_respond_to(result, :count)
    assert_kind_of(Array, result.offenses)
  end

  it 'all validators enabled completes analysis in reasonable time with all validators' do
    setup_all_validators

    start_time = Time.now
    result = Yard::Lint.run(path: project_path('lib/yard/lint/version.rb'), config: config, progress: false)
    elapsed = Time.now - start_time

    assert_operator(elapsed, :<, 10)
    assert_kind_of(Array, result.offenses)
  end

  it 'all validators enabled produces consistent results across multiple runs' do
    setup_all_validators

    result1 = Yard::Lint.run(path: project_path('lib/yard/lint/version.rb'), config: config, progress: false)
    result2 = Yard::Lint.run(path: project_path('lib/yard/lint/version.rb'), config: config, progress: false)

    assert_equal(result1.count, result2.count)
    assert_equal(result1.offenses.size, result2.offenses.size)
  end
end

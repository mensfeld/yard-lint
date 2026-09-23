# frozen_string_literal: true

describe 'Yard::Lint::Explainer' do
  # .call returns a formatted explanation string sourced from the validator's
  # own YARD doc block.

  it 'call renders the metadata header from the validator defaults' do
    output = Yard::Lint::Explainer.call('Tags/TypeSyntax')

    assert_includes(output, 'Tags/TypeSyntax')
    assert_includes(output, 'Enabled by default: true')
    assert_includes(output, 'Default severity:   warning')
    assert_includes(output, 'Configuration keys: ValidatedTags')
  end

  it 'call renders the description and configuration snippet from the doc block' do
    output = Yard::Lint::Explainer.call('Tags/TypeSyntax')

    assert_includes(output, 'Validates YARD type syntax')
    assert_includes(output, '## Configuration')
    assert_includes(output, 'Enabled: false')
  end

  it 'call renders both example labels under an Examples section' do
    output = Yard::Lint::Explainer.call('Tags/TypeSyntax')

    assert_includes(output, 'Examples:')
    assert_includes(output, 'Bad - Invalid type syntax that YARD cannot parse')
    assert_includes(output, 'Good - Valid parseable YARD type syntax')
  end

  it 'call omits the configuration keys line when there are none' do
    output = Yard::Lint::Explainer.call('Warnings/UnknownTag')

    refute_includes(output, 'Configuration keys:')
  end

  it 'call renders a doc block whose configuration precedes its examples' do
    output = Yard::Lint::Explainer.call('Tags/ApiTags')

    assert_includes(output, 'Tags/ApiTags')
    assert_includes(output, '## Configuration')
    assert_includes(output, 'Examples:')
  end

  it 'call raises ArgumentError for an unknown validator name' do
    error = assert_raises(ArgumentError) { Yard::Lint::Explainer.call('Bogus') }

    assert_includes(error.message, 'Bogus')
  end

  it 'call does not clobber a pre-existing YARD registry' do
    YARD::Registry.clear
    YARD.parse_string("# A documented class\nclass ExplainerProbe\nend\n")

    Yard::Lint::Explainer.call('Tags/TypeSyntax')

    probe = YARD::Registry.at('ExplainerProbe')
    refute_nil(probe, 'explaining a validator wiped the caller\'s registry')
    assert_equal('A documented class', probe.docstring.to_s)
  end

  it 'call explains a validator in every category' do
    %w[
      Documentation/UndocumentedObjects
      Tags/Order
      Semantic/AbstractMethods
      Warnings/UnknownTag
    ].each do |name|
      output = Yard::Lint::Explainer.call(name)

      assert_includes(output, name)
      refute_empty(output.strip)
    end
  end
end

# frozen_string_literal: true

describe 'Yard::Lint::Validators::Tags::TypeSyntax::Result' do
  it 'class attributes has default severity set to warning' do
    assert_equal('warning', Yard::Lint::Validators::Tags::TypeSyntax::Result.default_severity)
  end

  it 'class attributes has offense type set to method' do
    assert_equal('method', Yard::Lint::Validators::Tags::TypeSyntax::Result.offense_type)
  end

  it 'class attributes has offense name set to invalidtypesyntax' do
    assert_equal('InvalidTypeSyntax', Yard::Lint::Validators::Tags::TypeSyntax::Result.offense_name)
  end

  it 'build message delegates to messagesbuilder' do
    offense = {
      tag_name: 'param',
      type_string: 'Array<',
      error_message: "expecting name, got ''"
    }

    Yard::Lint::Validators::Tags::TypeSyntax::MessagesBuilder
      .stubs(:call)
      .with(offense)
      .returns('formatted message')

    result = Yard::Lint::Validators::Tags::TypeSyntax::Result.new([])
    message = result.build_message(offense)

    assert_equal('formatted message', message)
  end

  it 'inheritance inherits from results base' do
    assert_equal(Yard::Lint::Results::Base, Yard::Lint::Validators::Tags::TypeSyntax::Result.superclass)
  end
end


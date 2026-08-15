# frozen_string_literal: true

# Characterization test for the YARD behavior Tags/TagSeparator and
# Tags/TagGroupSeparator rely on to tell a module_function definition's authored
# docstring from the normalized copy YARD builds beside it.
#
# None of this is documented or promised by YARD, and the gemspec accepts any
# `yard ~> 0.9`. Asserting it here means a YARD change fails with a message
# naming the behavior that moved, rather than as a mysterious lint offense.
describe 'YARD module_function behavior the separator validators depend on' do
  # Every form in the fixture, as [namespace, method name]
  FORMS = [
    ['BareModuleFunctionExample', :bare_separated],
    ['SymbolModuleFunctionExample', :symbol_separated],
    ['DecoratorModuleFunctionExample', :decorator_separated]
  ].freeze

  attr_reader :objects

  # @return [Array<YARD::CodeObjects::MethodObject>] the pair YARD registers for
  #   one module_function definition, instance half first
  def pair_for(namespace, name)
    halves = objects.select { |o| o.namespace.path == namespace && o.name == name }

    assert_equal(%i[class instance], halves.map(&:scope).sort, "#{namespace}.#{name} was not registered twice")

    [halves.find { |o| o.scope == :instance }, halves.find { |o| o.scope == :class }]
  end

  # The normalized copy is the half whose blank lines between tags are gone
  def authored?(object)
    object.docstring.all.include?("\n\n")
  end

  before do
    YARD::Registry.clear
    YARD.parse([File.expand_path('../fixtures/module_function_example.rb', __dir__)])
    @objects = YARD::Registry.all(:method)
  end

  after { YARD::Registry.clear }

  it 'registers both halves at the same file and line' do
    FORMS.each do |namespace, name|
      instance_half, class_half = pair_for(namespace, name)

      assert_equal(instance_half.file, class_half.file, namespace)
      assert_equal(instance_half.line, class_half.line, namespace)
    end
  end

  it 'flags only the class half as a module function' do
    FORMS.each do |namespace, name|
      instance_half, class_half = pair_for(namespace, name)

      assert_predicate(class_half, :module_function?, namespace)
      refute_predicate(instance_half, :module_function?, namespace)
    end
  end

  it 'normalizes exactly one half of every pair' do
    FORMS.each do |namespace, name|
      halves = pair_for(namespace, name)

      assert_equal(1, halves.count { |o| authored?(o) }, "#{namespace}: expected exactly one authored half")
    end
  end

  it 'normalizes the copy by moving param types ahead of param names' do
    FORMS.each do |namespace, name|
      copy = pair_for(namespace, name).reject { |o| authored?(o) }.first

      assert_includes(copy.docstring.all, '@param [String] foo', namespace)
    end
  end

  it 'gives a line range only to the authored half, whichever half that is' do
    # Bare form: the public class method is authored, the private instance copy is not
    instance_half, class_half = pair_for('BareModuleFunctionExample', :bare_separated)

    assert(authored?(class_half) && class_half.docstring.line_range, 'bare form: class half is not the authored one')
    assert_nil(instance_half.docstring.line_range)

    # Symbol form: the halves swap roles
    instance_half, class_half = pair_for('SymbolModuleFunctionExample', :symbol_separated)

    assert(authored?(instance_half) && instance_half.docstring.line_range,
      'symbol form: instance half is not the authored one')
    assert_nil(class_half.docstring.line_range)
  end

  # This is the assumption module_function_copy? cannot verify. With no line
  # range on either half it falls back to treating the class half as the copy,
  # which is correct only while YARD copies in this direction.
  it 'leaves both halves of module_function def without a line range, the instance half authored' do
    instance_half, class_half = pair_for('DecoratorModuleFunctionExample', :decorator_separated)

    assert_nil(instance_half.docstring.line_range, 'decorator form: instance half gained a line range')
    assert_nil(class_half.docstring.line_range, 'decorator form: class half gained a line range')

    assert(authored?(instance_half), 'decorator form: the instance half is no longer the authored one')
    refute(authored?(class_half), 'decorator form: the class half is no longer the copy')
  end
end

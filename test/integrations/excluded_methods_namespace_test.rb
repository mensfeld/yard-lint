# frozen_string_literal: true

# Proves that Documentation/UndocumentedObjects' ExcludedMethods only excludes
# methods, never classes, modules, or constants. The exclusion derived a
# "method name" via element.split(/[#.]/).last, which for a namespace element
# (no #/. separator) returned the full object path - so a method-exclusion
# pattern like /cache/ silently suppressed the offense for class Memcached
# (whose name contains "cache") while still reporting its methods.
describe 'ExcludedMethods on namespaces' do
  attr_reader :result

  before do
    fixture_path = File.expand_path('../fixtures/excluded_methods_namespace.rb', __dir__)
    config = test_config do |c|
      c.set_validator_config('Documentation/UndocumentedObjects', 'ExcludedMethods', ['/cache/'])
    end
    @result = Yard::Lint.run(path: fixture_path, config: config, progress: false)
  end

  def undocumented?(element)
    result.offenses.any? do |o|
      o[:name] == 'UndocumentedObject' && o[:element] == element
    end
  end

  it 'still reports an undocumented class even when its name matches a method pattern' do
    assert(undocumented?('Memcached'), 'class Memcached was suppressed by a method exclusion')
  end

  it 'still excludes a method matching the ExcludedMethods pattern' do
    refute(undocumented?('Memcached#cache_get'), 'cache_get should be excluded by /cache/')
  end

  it 'still reports a method that does not match the pattern' do
    assert(undocumented?('Memcached#lookup'))
  end
end

# frozen_string_literal: true

require 'json'

describe 'Yard::Lint::Formatters::Sarif' do
  def offense(overrides = {})
    {
      validator: 'Documentation/UndocumentedObjects',
      name: 'UndocumentedObject',
      severity: 'warning',
      message: 'Documentation required for `Foo`',
      location: 'lib/foo.rb',
      location_line: 12
    }.merge(overrides)
  end

  def document(offenses, base_dir: Dir.pwd)
    Yard::Lint::Formatters::Sarif.new(offenses, base_dir: base_dir).document
  end

  it 'emits a SARIF 2.1.0 skeleton with the yard-lint driver' do
    doc = document([offense])

    assert_equal('2.1.0', doc['version'])
    assert_match(%r{sarif-2\.1\.0}, doc['$schema'])
    driver = doc['runs'][0]['tool']['driver']
    assert_equal('yard-lint', driver['name'])
    assert_equal(Yard::Lint::VERSION, driver['version'])
  end

  it 'produces one result per offense with rule, level, message, and location' do
    doc = document([offense])
    result = doc['runs'][0]['results'][0]

    assert_equal('Documentation/UndocumentedObjects', result['ruleId'])
    assert_equal(0, result['ruleIndex'])
    assert_equal('warning', result['level'])
    assert_equal('Documentation required for `Foo`', result['message']['text'])

    physical = result['locations'][0]['physicalLocation']
    assert_equal('lib/foo.rb', physical['artifactLocation']['uri'])
    assert_equal(12, physical['region']['startLine'])
  end

  it 'maps yard-lint severities onto SARIF levels' do
    offenses = [
      offense(severity: 'error'),
      offense(severity: 'warning'),
      offense(severity: 'convention'),
      offense(severity: 'never')
    ]
    levels = document(offenses)['runs'][0]['results'].map { |r| r['level'] }

    assert_equal(%w[error warning note none], levels)
  end

  it 'falls back to warning for an unrecognized severity' do
    doc = document([offense(severity: 'bizarre')])

    assert_equal('warning', doc['runs'][0]['results'][0]['level'])
  end

  it 'emits one rich rule per distinct validator, sourced from the Explainer' do
    doc = document([offense, offense(location_line: 20)])
    rules = doc['runs'][0]['tool']['driver']['rules']

    assert_equal(1, rules.length, 'expected the repeated validator to be deduplicated')
    rule = rules[0]
    assert_equal('Documentation/UndocumentedObjects', rule['id'])
    assert_equal('UndocumentedObjects', rule['name'])
    assert_match(%r{wiki/Validators}, rule['helpUri'])
    assert_includes(%w[error warning note none], rule['defaultConfiguration']['level'])
    refute_empty(rule['shortDescription']['text'])
    assert_match(/documentation/i, rule['fullDescription']['text'])
  end

  it 'assigns rule indexes that resolve to the rules array' do
    offenses = [
      offense(validator: 'Documentation/UndocumentedObjects'),
      offense(validator: 'Tags/Order', message: 'wrong order')
    ]
    doc = document(offenses)
    rules = doc['runs'][0]['tool']['driver']['rules']
    results = doc['runs'][0]['results']

    results.each do |result|
      assert_equal(result['ruleId'], rules[result['ruleIndex']]['id'])
    end
  end

  it 'makes absolute paths repository-relative against base_dir' do
    doc = document([offense(location: '/repo/lib/foo.rb')], base_dir: '/repo')

    uri = doc['runs'][0]['results'][0]['locations'][0]['physicalLocation']['artifactLocation']['uri']
    assert_equal('lib/foo.rb', uri)
  end

  it 'keeps a path outside base_dir rather than emitting a ../ or absolute URI mismatch' do
    doc = document([offense(location: '/elsewhere/foo.rb')], base_dir: '/repo')

    uri = doc['runs'][0]['results'][0]['locations'][0]['physicalLocation']['artifactLocation']['uri']
    refute(uri.start_with?('..'), "expected no ../ URI, got #{uri}")
  end

  it 'defaults a missing or zero line to 1 (SARIF regions are 1-based)' do
    doc = document([offense(location_line: nil, line: nil)])

    assert_equal(1, doc['runs'][0]['results'][0]['locations'][0]['physicalLocation']['region']['startLine'])
  end

  it 'omits ruleId/ruleIndex (rather than emitting null) for an offense with no validator' do
    doc = document([offense(validator: nil)])
    result = doc['runs'][0]['results'][0]

    refute(result.key?('ruleId'), 'ruleId must be omitted, not null')
    refute(result.key?('ruleIndex'), 'ruleIndex must be omitted, not null (null is schema-invalid)')
    assert_empty(doc['runs'][0]['tool']['driver']['rules'])
    # The result is still emitted with its level, message, and location.
    assert_equal('warning', result['level'])
    assert_equal('lib/foo.rb', result['locations'][0]['physicalLocation']['artifactLocation']['uri'])
  end

  it 'attaches a stable, line-independent partialFingerprint to each result' do
    at_line_10 = document([offense(location_line: 10)])['runs'][0]['results'][0]
    at_line_99 = document([offense(location_line: 99)])['runs'][0]['results'][0]

    key = 'yardLintOffense/v1'
    fingerprint = at_line_10['partialFingerprints'][key]
    assert_match(/\A[0-9a-f]{64}\z/, fingerprint)
    assert_equal(
      fingerprint,
      at_line_99['partialFingerprints'][key],
      'fingerprint must not change when only the line number shifts'
    )
  end

  it 'gives different offenses different fingerprints' do
    key = 'yardLintOffense/v1'
    base = document([offense])['runs'][0]['results'][0]['partialFingerprints'][key]

    different_element = document([offense(element: 'Foo#other')])['runs'][0]['results'][0]['partialFingerprints'][key]
    different_file = document([offense(location: 'lib/bar.rb')])['runs'][0]['results'][0]['partialFingerprints'][key]
    different_validator = document([offense(validator: 'Tags/Order')])['runs'][0]['results'][0]['partialFingerprints'][key]

    refute_equal(base, different_element)
    refute_equal(base, different_file)
    refute_equal(base, different_validator)
  end

  it 'falls back to the message for fingerprinting when the offense has no element' do
    key = 'yardLintOffense/v1'
    base = { validator: 'Tags/TypeSyntax', severity: 'warning', location: 'lib/foo.rb' }
    fp = lambda do |o|
      document([o])['runs'][0]['results'][0]['partialFingerprints'][key]
    end

    # Distinct messages in the same file must not collapse into one fingerprint.
    refute_equal(
      fp.call(base.merge(message: 'invalid type in @param', location_line: 1)),
      fp.call(base.merge(message: 'invalid type in @return', location_line: 2))
    )

    # Whitespace is collapsed and the line is ignored...
    assert_equal(
      fp.call(base.merge(message: 'Invalid  type', location_line: 1)),
      fp.call(base.merge(message: 'Invalid type', location_line: 40))
    )

    # ...but case is preserved, so messages differing only in case (e.g.
    # case-sensitive type names) do not collapse into one fingerprint.
    refute_equal(
      fp.call(base.merge(message: "invalid type 'Foo'")),
      fp.call(base.merge(message: "invalid type 'foo'"))
    )
  end

  it 'does not collide an element with an element-less message of the same text' do
    key = 'yardLintOffense/v1'
    base = { validator: 'Tags/TypeSyntax', severity: 'warning', location: 'lib/foo.rb' }
    fp = ->(o) { document([o])['runs'][0]['results'][0]['partialFingerprints'][key] }

    with_element = fp.call(base.merge(element: 'foo', message: 'ignored'))
    with_message = fp.call(base.merge(message: 'foo')) # no element

    refute_equal(with_element, with_message)
  end

  it 'ignores the message when the offense identifies an object (element present)' do
    key = 'yardLintOffense/v1'
    with_element = ->(msg) { document([offense(element: 'Foo#bar', message: msg)])['runs'][0]['results'][0]['partialFingerprints'][key] }

    assert_equal(with_element.call('one wording'), with_element.call('a completely different wording'))
  end

  it 'produces valid SARIF with empty results and rules when there are no offenses' do
    doc = document([])

    assert_equal('2.1.0', doc['version'])
    assert_empty(doc['runs'][0]['results'])
    assert_empty(doc['runs'][0]['tool']['driver']['rules'])
  end

  it 'generate returns parseable JSON' do
    json = Yard::Lint::Formatters::Sarif.new([offense]).generate

    parsed = JSON.parse(json)
    assert_equal('2.1.0', parsed['version'])
  end
end

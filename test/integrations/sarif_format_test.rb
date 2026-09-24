# frozen_string_literal: true

require 'English'
require 'json'
require 'shellwords'
require 'tmpdir'

# Proves the `--format sarif` output end-to-end: a valid SARIF 2.1.0 document
# with the yard-lint driver, rich per-validator rules sourced from the Explainer,
# results with mapped levels and repository-relative locations, a truthful exit
# code, and clean stdout. Also pins backwards compatibility: the existing text,
# json, and quickfix formats are unchanged and unknown formats are still rejected.
# Each run uses an explicit `-c` config and cd's into the temp dir so paths are
# resolved deterministically (not against the repository's own .yard-lint.yml).
describe 'CLI --format sarif' do
  attr_reader :bin_path

  before do
    @bin_path = File.expand_path('../../bin/yard-lint', __dir__)
  end

  def undocumented_source
    "class Foo\n  def bar\n  end\nend\n"
  end

  def documented_source
    "# A documented class\n# @return [void]\nclass Clean\nend\n"
  end

  # Runs yard-lint in a temp dir (as the working directory, so SARIF URIs come
  # out repository-relative) with the given source and config, for the given
  # extra CLI args. Returns [stdout, exit_status].
  def run_cli(args, source: undocumented_source, config: '')
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, 'foo.rb'), source)
      File.write(File.join(dir, '.yard-lint.yml'), config)

      output = IO.popen(
        "cd #{Shellwords.escape(dir)} && #{bin_path} -c .yard-lint.yml #{args} foo.rb 2>&1",
        &:read
      )
      [output, $CHILD_STATUS.exitstatus]
    end
  end

  def sarif(args: '--only Documentation/UndocumentedObjects', **opts)
    output, status = run_cli("#{args} --format sarif --no-progress", **opts)
    [JSON.parse(output), status]
  end

  it 'emits a valid SARIF 2.1.0 document with the yard-lint driver' do
    doc, = sarif

    assert_equal('2.1.0', doc['version'])
    assert_match(%r{sarif-2\.1\.0}, doc['$schema'])
    driver = doc['runs'][0]['tool']['driver']
    assert_equal('yard-lint', driver['name'])
    assert_match(/\A\d+\.\d+\.\d+/, driver['version'])
    assert_match(%r{github\.com/mensfeld/yard-lint}, driver['informationUri'])
  end

  it 'reports each offense as a SARIF result with rule, level, message, and location' do
    doc, = sarif
    results = doc['runs'][0]['results']

    refute_empty(results)
    results.each do |result|
      assert_equal('Documentation/UndocumentedObjects', result['ruleId'])
      assert_kind_of(Integer, result['ruleIndex'])
      assert_equal('warning', result['level'])
      refute_empty(result['message']['text'])
      region = result['locations'][0]['physicalLocation']['region']
      assert_operator(region['startLine'], :>=, 1)
    end
  end

  it 'uses repository-relative artifact URIs (not absolute) so GitHub can map them' do
    doc, = sarif
    uris = doc['runs'][0]['results'].map do |r|
      r['locations'][0]['physicalLocation']['artifactLocation']['uri']
    end

    refute_empty(uris)
    uris.each do |uri|
      assert_equal('foo.rb', uri)
      refute(uri.start_with?('/'), "expected a relative URI, got #{uri}")
    end
  end

  it 'emits a rich, deduplicated rule per validator sourced from the Explainer' do
    doc, = sarif
    rules = doc['runs'][0]['tool']['driver']['rules']

    assert_equal(1, rules.length)
    rule = rules[0]
    assert_equal('Documentation/UndocumentedObjects', rule['id'])
    assert_equal('UndocumentedObjects', rule['name'])
    assert_match(%r{wiki/Validators}, rule['helpUri'])
    assert_includes(%w[error warning note none], rule['defaultConfiguration']['level'])
    refute_empty(rule['shortDescription']['text'])
    assert_match(/documentation/i, rule['fullDescription']['text'])
  end

  it 'maps a category-lowered convention severity to the SARIF note level' do
    doc, = sarif(config: "Documentation:\n  Severity: convention\n")
    levels = doc['runs'][0]['results'].map { |r| r['level'] }

    refute_empty(levels)
    assert(levels.all? { |l| l == 'note' }, "expected all note, got #{levels}")
  end

  it 'maps a category-raised error severity to the SARIF error level' do
    doc, = sarif(config: "Documentation:\n  Severity: error\n")
    levels = doc['runs'][0]['results'].map { |r| r['level'] }

    refute_empty(levels)
    assert(levels.all? { |l| l == 'error' }, "expected all error, got #{levels}")
  end

  it 'fails the run (non-zero exit) when reportable offenses exist' do
    _, status = sarif

    assert_equal(1, status)
  end

  it 'emits valid, empty SARIF and exits 0 for a clean file' do
    doc, status = sarif(source: documented_source)

    assert_equal(0, status)
    assert_equal('2.1.0', doc['version'])
    assert_empty(doc['runs'][0]['results'])
    assert_empty(doc['runs'][0]['tool']['driver']['rules'])
  end

  it 'writes nothing but SARIF JSON to stdout (parseable, no progress noise)' do
    output, = run_cli('--only Documentation/UndocumentedObjects --format sarif --no-progress')

    # The entire stdout must parse as JSON.
    assert(JSON.parse(output))
  end

  it 'accepts sarif as a valid format up front' do
    output, status = run_cli('--format sarif --no-progress', source: documented_source)

    assert_equal(0, status)
    refute_match(/Unknown format/, output)
  end

  # --- Backwards compatibility -------------------------------------------------

  it 'still rejects a genuinely unknown format, now listing sarif as valid' do
    output, status = run_cli('--format xml')

    assert_equal(1, status)
    assert_match(/Unknown format 'xml'/, output)
    assert_match(/sarif/, output)
  end

  it 'leaves the json format unchanged' do
    output, = run_cli('--only Documentation/UndocumentedObjects --format json --no-progress')
    parsed = JSON.parse(output)

    assert(parsed.key?('offense_count'))
    assert(parsed.key?('offenses'))
    refute(parsed.key?('runs'), 'json format must not turn into SARIF')
  end

  it 'leaves the quickfix format unchanged' do
    output, = run_cli('--only Documentation/UndocumentedObjects --format quickfix --no-progress')

    output.lines.map(&:chomp).reject(&:empty?).each do |line|
      assert_match(/\A.+:\d+: [EWC?]: .+: .+\z/, line, "unexpected quickfix line: #{line.inspect}")
    end
  end

  it 'leaves the default text format unchanged' do
    output, = run_cli('--only Documentation/UndocumentedObjects --no-progress')

    assert_match(/offense/i, output)
    refute_match(/"\$schema"/, output)
  end
end

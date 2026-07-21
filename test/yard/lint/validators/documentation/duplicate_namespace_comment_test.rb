# frozen_string_literal: true

describe 'Yard::Lint::Validators::Documentation::DuplicateNamespaceComment' do
  it 'is a module' do
    assert_kind_of(Module, Yard::Lint::Validators::Documentation::DuplicateNamespaceComment)
  end

  it 'has required sub modules and classes' do
    mod = Yard::Lint::Validators::Documentation::DuplicateNamespaceComment
    assert_equal(true, mod.const_defined?(:Config))
    assert_equal(true, mod.const_defined?(:Validator))
    assert_equal(true, mod.const_defined?(:Parser))
    assert_equal(true, mod.const_defined?(:Result))
    assert_equal(true, mod.const_defined?(:MessagesBuilder))
  end

  it 'is discovered by the config loader' do
    assert_includes(
      Yard::Lint::ConfigLoader::ALL_VALIDATORS,
      'Documentation/DuplicateNamespaceComment'
    )
  end
end

describe 'Yard::Lint::Validators::Documentation::DuplicateNamespaceComment::Config' do
  it 'id returns the validator identifier' do
    assert_equal(
      :duplicate_namespace_comment,
      Yard::Lint::Validators::Documentation::DuplicateNamespaceComment::Config.id
    )
  end

  it 'defaults returns default configuration' do
    assert_equal(
      { 'Enabled' => true, 'Severity' => 'warning' },
      Yard::Lint::Validators::Documentation::DuplicateNamespaceComment::Config.defaults
    )
  end

  it 'defaults returns frozen hash' do
    assert_predicate(
      Yard::Lint::Validators::Documentation::DuplicateNamespaceComment::Config.defaults,
      :frozen?
    )
  end

  it 'inheritance inherits from base config class' do
    assert_equal(
      Yard::Lint::Validators::Config,
      Yard::Lint::Validators::Documentation::DuplicateNamespaceComment::Config.superclass
    )
  end
end

describe 'Yard::Lint::Validators::Documentation::DuplicateNamespaceComment::Validator' do
  it 'supports in-process execution' do
    assert_equal(
      true,
      Yard::Lint::Validators::Documentation::DuplicateNamespaceComment::Validator.in_process?
    )
  end

  it 'inherits from the base validator' do
    validator = Yard::Lint::Validators::Documentation::DuplicateNamespaceComment::Validator.new(
      Yard::Lint::Config.new, ['lib/example.rb']
    )
    assert_kind_of(Yard::Lint::Validators::Base, validator)
  end

  it 'treats an unreadable definition site as undocumented' do
    validator = Yard::Lint::Validators::Documentation::DuplicateNamespaceComment::Validator.new(
      Yard::Lint::Config.new, []
    )

    refute(validator.send(:documented_site?, '/nonexistent/does_not_exist.rb', 5))
  end
end

describe 'Yard::Lint::Validators::Documentation::DuplicateNamespaceComment::Parser' do
  def parser
    Yard::Lint::Validators::Documentation::DuplicateNamespaceComment::Parser.new
  end

  it 'returns an empty array for empty input' do
    assert_empty(parser.call(''))
    assert_empty(parser.call(nil))
  end

  it 'parses a single offense line' do
    line = "/a.rb:6: Foo::Bar\t/a.rb:6|/b.rb:9\tdiffer"

    assert_equal(
      [
        {
          location: '/a.rb',
          line: 6,
          namespace: 'Foo::Bar',
          sites: ['/a.rb:6', '/b.rb:9'],
          conflict: 'differ'
        }
      ],
      parser.call(line)
    )
  end

  it 'parses a fully qualified namespace that contains ::' do
    line = "/x.rb:3: Yard::Lint::Validators::Warnings\t/x.rb:3|/y.rb:3\tsame"
    parsed = parser.call(line).first

    assert_equal('Yard::Lint::Validators::Warnings', parsed[:namespace])
    assert_equal('same', parsed[:conflict])
  end

  it 'parses multiple lines and skips malformed ones' do
    output = [
      "/a.rb:1: A\t/a.rb:1|/b.rb:1\tsame",
      'garbage-without-location',
      "/c.rb:2: C\t/c.rb:2|/d.rb:2\tdiffer"
    ].join("\n")

    parsed = parser.call(output)

    assert_equal(2, parsed.size)
    assert_equal(%w[A C], parsed.map { |offense| offense[:namespace] })
  end
end

describe 'Yard::Lint::Validators::Documentation::DuplicateNamespaceComment::MessagesBuilder' do
  def build(offense)
    Yard::Lint::Validators::Documentation::DuplicateNamespaceComment::MessagesBuilder.call(offense)
  end

  it 'names the namespace, count and locations' do
    message = build(namespace: 'Foo::Bar', sites: ['a.rb:1', 'b.rb:2'], conflict: 'same')

    assert_includes(message, '`Foo::Bar`')
    assert_includes(message, 'documented in 2 files')
    assert_includes(message, 'a.rb:1')
    assert_includes(message, 'b.rb:2')
  end

  it 'notes lost content only when the docstrings differ' do
    differ = build(namespace: 'A', sites: ['a.rb:1', 'b.rb:2'], conflict: 'differ')
    same = build(namespace: 'A', sites: ['a.rb:1', 'b.rb:2'], conflict: 'same')

    assert_includes(differ, 'docstrings differ')
    refute_includes(same, 'docstrings differ')
  end

  it 'truncates long location lists' do
    sites = (1..8).map { |i| "file_#{i}.rb:#{i}" }
    message = build(namespace: 'A', sites: sites, conflict: 'same')

    assert_includes(message, 'documented in 8 files')
    assert_includes(message, '(+3 more)')
  end

  it 'leaves a location with no line number untouched' do
    klass = Yard::Lint::Validators::Documentation::DuplicateNamespaceComment::MessagesBuilder

    assert_equal('plainpath', klass.send(:relativize, 'plainpath'))
  end
end

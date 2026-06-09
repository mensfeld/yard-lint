# frozen_string_literal: true

describe 'Yard::Lint' do
  attr_reader :test_file

  it 'version has a version number' do
    refute_nil(Yard::Lint::VERSION)
    assert_match(/\d+\.\d+\.\d+/, Yard::Lint::VERSION)
  end

  before do
    @test_file = '/tmp/test_lint.rb'
    File.write(test_file, <<~RUBY)
    # A simple test class
    class TestClass
    def method_with_params(arg1, arg2)
    arg1 + arg2
    end
    end
    RUBY
  end

  after do
    FileUtils.rm_f(test_file)
  end

  it 'run returns a result object' do
    result = Yard::Lint.run(path: test_file)

    assert_kind_of(Yard::Lint::Results::Aggregate, result)
  end

  it 'run accepts a config object' do
    config = Yard::Lint::Config.new do |c|
      c.options = ['--private']
      end
    result = Yard::Lint.run(path: test_file, config: config)

    assert_kind_of(Yard::Lint::Results::Aggregate, result)
  end

  it 'run filters excluded files' do
    config = Yard::Lint::Config.new do |c|
      c.exclude = ['/tmp/**/*']
      end
    result = Yard::Lint.run(path: test_file, config: config)

    # Should be clean since file is excluded
    assert_equal(true, result.clean?)
  end

  it 'run source: lints from memory without the file existing on disk' do
    source = <<~RUBY
      # A documented class
      class MemoryClass
        def undocumented_method(arg)
          arg
        end
      end
    RUBY

    result = Yard::Lint.run(path: '/nonexistent/memory.rb', source: source, progress: false)

    assert_kind_of(Yard::Lint::Results::Aggregate, result)
  end

  it 'run source: detects offenses in in-memory source' do
    source = <<~RUBY
      class UndocumentedInMemory
        def method_missing_docs(arg)
          arg
        end
      end
    RUBY

    config = test_config
    result = Yard::Lint.run(path: '/virtual/undocumented.rb', source: source, config: config, progress: false)

    refute(result.clean?)
  end

  it 'run source: reports offense location pointing to the virtual path' do
    source = <<~RUBY
      class NoDocVirtual
        def undoc(arg)
          arg
        end
      end
    RUBY

    config = test_config
    result = Yard::Lint.run(path: '/virtual/path/reported.rb', source: source, config: config, progress: false)

    assert(result.offenses.any?)
    result.offenses.each do |offense|
      assert_equal('/virtual/path/reported.rb', offense[:location])
    end
  end

  it 'run source: produces identical offense names to disk-based linting for the same content' do
    disk_result = Yard::Lint.run(path: test_file, progress: false)
    YARD::Registry.clear
    source_result = Yard::Lint.run(path: test_file, source: File.read(test_file), progress: false)

    disk_names = disk_result.offenses.map { |o| o[:name] }.sort
    source_names = source_result.offenses.map { |o| o[:name] }.sort
    assert_equal(disk_names, source_names)
  end

  it 'run source: still applies exclusions when source is given' do
    source = <<~RUBY
      class ExcludedInMemory
        def undoc(arg); arg; end
      end
    RUBY

    config = Yard::Lint::Config.new do |c|
      c.exclude = ['/virtual/**/*']
    end
    result = Yard::Lint.run(path: '/virtual/excluded.rb', source: source, config: config, progress: false)

    assert(result.clean?)
  end

  it 'run source: raises ArgumentError when source is given with a directory path' do
    Dir.mktmpdir do |dir|
      assert_raises(ArgumentError) do
        Yard::Lint.run(path: dir, source: 'class Foo; end', progress: false)
      end
    end
  end

  it 'run source: raises ArgumentError when source is given with a glob pattern' do
    assert_raises(ArgumentError) do
      Yard::Lint.run(path: 'lib/**/*.rb', source: 'class Foo; end', progress: false)
    end
  end

  it 'run source: raises ArgumentError when source is given with an array of paths' do
    assert_raises(ArgumentError) do
      Yard::Lint.run(path: ['lib/foo.rb', 'lib/bar.rb'], source: 'class Foo; end', progress: false)
    end
  end

  # Config loading and path expansion are tested through integration tests
  # that call .run() - no need to test private implementation details directly
end


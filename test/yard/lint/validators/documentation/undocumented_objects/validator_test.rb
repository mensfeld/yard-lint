# frozen_string_literal: true

describe 'Yard::Lint::Validators::Documentation::UndocumentedObjects::Validator' do
  attr_reader :config, :selection, :validator, :collector

  before do
    @config = Yard::Lint::Config.new
    @selection = ['lib/example.rb']
    @validator = Yard::Lint::Validators::Documentation::UndocumentedObjects::Validator.new(config, selection)
    @collector = Yard::Lint::Executor::ResultCollector.new
  end

  after { YARD::Registry.clear }

  it 'initialize inherits from base validator' do
    assert_kind_of(Yard::Lint::Validators::Base, validator)
  end

  it 'initialize stores config and selection' do
  end

  it 'in process returns true for in process execution' do
    assert_equal(true, Yard::Lint::Validators::Documentation::UndocumentedObjects::Validator.in_process?)
  end

  it 'reports an undocumented module_function pair once, on the module method' do
    parse(<<~RUBY)
      module Example
        module_function

        def run(a); end
      end
    RUBY

    assert_equal(['Example.run|1'], reported('Example#run', 'Example.run'))
  end

  it 'reports an undocumented module_function :name pair once, on the module method' do
    parse(<<~RUBY)
      module Example
        def run; end
        module_function :run
      end
    RUBY

    assert_equal(['Example.run|0'], reported('Example#run', 'Example.run'))
  end

  it 'reports an undocumented module_function predicate whose copy has an inferred @return' do
    parse(<<~RUBY)
      module Example
        def ready?; end
        module_function :ready?
      end
    RUBY

    refute_empty(YARD::Registry.at('Example.ready?').docstring.all)
    assert_equal(['Example.ready?|0'], reported('Example#ready?', 'Example.ready?'))
  end

  it 'reports an undocumented predicate whose instance half has an inferred @return' do
    parse(<<~RUBY)
      module Example
        module_function

        def ready?; end
      end
    RUBY
    YARD::Registry.at('Example#ready?').docstring = '@return [Boolean] '

    assert_equal(['Example.ready?|0'], reported('Example#ready?', 'Example.ready?'))
  end

  it 'does not report a documented module_function pair' do
    parse(<<~RUBY)
      module Example
        # Tells if ready
        def ready?; end
        module_function :ready?
      end
    RUBY

    assert_empty(reported('Example#ready?', 'Example.ready?'))
  end

  it 'reports an undocumented private instance method that is not a module_function copy' do
    parse(<<~RUBY)
      module Example
        private

        def run; end
      end
    RUBY

    assert_equal(['Example#run|0'], reported('Example#run'))
  end

  private

  def parse(source)
    YARD::Registry.clear
    YARD.parse_string(source)
  end

  # @return [Array<String>] the offense lines without the file:line prefix
  def reported(*paths)
    paths.each { |path| validator.in_process_query(YARD::Registry.at(path), collector) }

    collector.to_stdout.lines.map { |line| line.split(': ', 2).last.chomp }
  end
end

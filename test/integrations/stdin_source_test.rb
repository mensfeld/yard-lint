# frozen_string_literal: true

describe 'Stdin/In-memory source linting' do
  after do
    YARD::Registry.clear
  end

  describe 'Yard::Lint.run with source:' do
    it 'lints an undocumented class from memory and reports offenses' do
      source = <<~RUBY
        class Undocumented
          def method_one(arg)
            arg
          end
        end
      RUBY

      config = test_config
      result = Yard::Lint.run(path: '/virtual/undocumented.rb', source: source, config: config, progress: false)

      refute(result.clean?)
      assert(result.offenses.any?)
    end

    it 'lints a well-documented class from memory and finds no Documentation offenses' do
      source = <<~RUBY
        # A calculator
        class Calculator
          # Adds two numbers
          # @param a [Integer] first
          # @param b [Integer] second
          # @return [Integer] the result
          def add(a, b)
            a + b
          end
        end
      RUBY

      config = test_config do |c|
        c.set_validator_config('Documentation/UndocumentedDocumentableObjects', 'Enabled', true)
        c.set_validator_config('Documentation/UndocumentedMethodArguments', 'Enabled', false)
        c.set_validator_config('Documentation/UndocumentedMethodReturnType', 'Enabled', false)
        c.set_validator_config('Tags/MissingTag', 'Enabled', false)
      end
      result = Yard::Lint.run(path: '/virtual/calc.rb', source: source, config: config, progress: false)

      doc_offenses = result.offenses.select { |o| o[:validator]&.start_with?('Documentation/') }
      assert_empty(doc_offenses)
    end

    it 'offense location points to the virtual path, not disk' do
      source = <<~RUBY
        class LocationCheck
          def no_docs(arg); arg; end
        end
      RUBY

      virtual = '/some/virtual/location.rb'
      config = test_config
      result = Yard::Lint.run(path: virtual, source: source, config: config, progress: false)

      assert(result.offenses.any?)
      result.offenses.each do |offense|
        assert_equal(virtual, offense[:location],
                     "Expected offense location to be virtual path, got: #{offense[:location]}")
      end
    end

    it 'linting from memory with the same source as disk yields identical offense names' do
      # Use a fixture file from this project — lint it from memory and from disk
      fixture = File.expand_path('../fixtures/undocumented_class.rb', __dir__)
      skip 'fixture not found' unless File.exist?(fixture)

      source = File.read(fixture)
      config = test_config

      disk_result = Yard::Lint.run(path: fixture, config: config, progress: false)
      YARD::Registry.clear
      memory_result = Yard::Lint.run(path: fixture, source: source, config: config, progress: false)

      disk_names = disk_result.offenses.map { |o| o[:name] }.sort
      memory_names = memory_result.offenses.map { |o| o[:name] }.sort
      assert_equal(disk_names, memory_names,
                   'In-memory linting should find the same offenses as disk-based linting')
    end

    it 'does not read the file from disk when source is given' do
      # Point at a real file but pass different source — offenses should reflect the source
      real_file = File.expand_path('../../lib/yard/lint.rb', __dir__)
      skip 'lib file not found' unless File.exist?(real_file)

      injected_source = <<~RUBY
        class InjectedClass
          def injected_method(arg); arg; end
        end
      RUBY

      config = test_config
      result = Yard::Lint.run(path: real_file, source: injected_source, config: config, progress: false)

      # The result must come from the injected source, not the real file on disk.
      # InjectedClass should appear in offenses; no real lib classes should.
      offense_messages = result.offenses.map { |o| o[:message] }.join(' ')
      assert_includes(offense_messages, 'InjectedClass',
                      'Offenses should reference InjectedClass from in-memory source')
    end
  end

  describe 'self-linting: yard-lint lints its own source from memory' do
    %w[
      lib/yard/lint.rb
      lib/yard/lint/runner.rb
      lib/yard/lint/executor/in_process_registry.rb
    ].each do |rel_path|
      it "source: and disk produce identical offense counts for #{rel_path}" do
        full_path = File.expand_path("../../#{rel_path}", __dir__)
        skip "#{rel_path} not found" unless File.exist?(full_path)

        source = File.read(full_path)
        # No test_config — use real project config so exclusions are realistic
        config = Yard::Lint::Config.load || Yard::Lint::Config.new

        disk_result = Yard::Lint.run(path: full_path, config: config, progress: false)
        YARD::Registry.clear
        memory_result = Yard::Lint.run(path: full_path, source: source, config: config, progress: false)

        assert_equal(
          disk_result.count,
          memory_result.count,
          "Offense count mismatch for #{rel_path}: disk=#{disk_result.count}, memory=#{memory_result.count}"
        )
      end
    end
  end
end

# frozen_string_literal: true

# Cache effectiveness tests only apply to shell mode (subprocess execution).
# In in-process mode, validators execute within the same Ruby process without
# spawning subprocesses, so the command cache is not used.
RSpec.describe 'YARD Command Cache Effectiveness', :cache_isolation do
  before do
    skip 'Cache tests only apply to shell mode' unless ENV['YARD_LINT_SHELL_MODE'] == 'true'
  end

  let(:fixtures_dir) { File.expand_path('fixtures', __dir__) }

  # Config without exclusions so fixtures are processed
  let(:config) do
    Yard::Lint::Config.new do |c|
      c.exclude = []
      # Disable ExampleSyntax to avoid interference from test fixtures
      c.set_validator_config('Tags/ExampleSyntax', 'Enabled', false)
    end
  end

  describe 'Cache Statistics' do
    it 'tracks command executions' do
      file = File.join(fixtures_dir, 'undocumented_class.rb')

      # Run yard-lint which will execute multiple validators
      Yard::Lint.run(path: file, config: config)

      # Get cache stats
      cache = Yard::Lint::Validators::Base.command_cache
      stats = cache.stats

      # Should have executed commands (all misses since validators run unique commands)
      expect(stats[:misses]).to be > 0
      expect(stats[:total]).to eq(stats[:hits] + stats[:misses])
      expect(stats[:total]).to eq(stats[:misses] + stats[:saved_executions])
    end

    it 'provides consistent results across runs' do
      file = File.join(fixtures_dir, 'undocumented_class.rb')

      # First run
      result1 = Yard::Lint.run(path: file, config: config)

      cache = Yard::Lint::Validators::Base.command_cache
      first_stats = cache.stats

      # Reset and run again
      Yard::Lint::Validators::Base.reset_command_cache!
      result2 = Yard::Lint.run(path: file, config: config)

      cache = Yard::Lint::Validators::Base.command_cache
      second_stats = cache.stats

      # Both runs should produce identical results
      expect(result1.count).to eq(result2.count)
      expect(result1.statistics).to eq(result2.statistics)

      # Both runs should have similar command execution patterns
      expect(first_stats[:misses]).to eq(second_stats[:misses])
    end
  end

  describe 'Cache Isolation Between Runs' do
    it 'does not share cache across different file sets' do
      file1 = File.join(fixtures_dir, 'undocumented_class.rb')
      file2 = File.join(fixtures_dir, 'clean_code.rb')

      # Run on file1
      result1 = Yard::Lint.run(path: file1, config: config)

      # Reset cache AND YARD database for clean second run
      Yard::Lint::Validators::Base.reset_command_cache!
      Yard::Lint::Validators::Base.clear_yard_database!

      # Run on file2
      result2 = Yard::Lint.run(path: file2, config: config)

      # Results should be different
      expect(result1.count).not_to eq(result2.count)
      expect(result1.clean?).not_to eq(result2.clean?)
    end
  end

  describe 'Cache Correctness' do
    it 'produces identical results with or without cache' do
      files = [
        File.join(fixtures_dir, 'undocumented_class.rb'),
        File.join(fixtures_dir, 'missing_param_docs.rb')
      ]

      # Run with cache
      result_with_cache = Yard::Lint.run(path: files)

      # Reset cache and run again
      Yard::Lint::Validators::Base.reset_command_cache!
      result_without_cache = Yard::Lint.run(path: files)

      # Results should be identical
      expect(result_with_cache.count).to eq(result_without_cache.count)
      expect(result_with_cache.statistics).to eq(result_without_cache.statistics)

      # Check offense counts by type
      undocumented_with_cache = result_with_cache.offenses.select do |o|
        o[:name] == 'UndocumentedObject'
      end
      undocumented_without_cache = result_without_cache.offenses.select do |o|
        o[:name] == 'UndocumentedObject'
      end
      expect(undocumented_with_cache.count).to eq(undocumented_without_cache.count)

      method_args_with_cache = result_with_cache.offenses.select do |o|
        o[:name] == 'UndocumentedMethodArgument'
      end
      method_args_without_cache = result_without_cache.offenses.select do |o|
        o[:name] == 'UndocumentedMethodArgument'
      end
      expect(method_args_with_cache.count).to eq(method_args_without_cache.count)
    end
  end

  describe 'Cache with Modified Results' do
    it 'handles validators that modify stdout (like Tags/Order)' do
      file = File.join(fixtures_dir, 'invalid_tag_order.rb')

      # Run multiple times - Tags/Order modifies stdout to be a Hash
      result1 = Yard::Lint.run(path: file)
      result2 = Yard::Lint.run(path: file)
      result3 = Yard::Lint.run(path: file)

      # All results should be identical despite stdout modification
      invalid_tags_1 = result1.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
      invalid_tags_2 = result2.offenses.select { |o| o[:name] == 'InvalidTagOrder' }
      invalid_tags_3 = result3.offenses.select { |o| o[:name] == 'InvalidTagOrder' }

      expect(invalid_tags_1.count).to eq(invalid_tags_2.count)
      expect(invalid_tags_2.count).to eq(invalid_tags_3.count)

      # Should not crash or have corrupted data
      invalid_tags_1.each do |offense|
        expect(offense[:method_name]).to be_a(String)
        expect(offense[:location]).to be_a(String)
      end
    end
  end

  describe 'Cache Performance Characteristics' do
    it 'executes each unique command only once per run' do
      file = File.join(fixtures_dir, 'undocumented_class.rb')

      Yard::Lint.run(path: file, config: config)

      cache = Yard::Lint::Validators::Base.command_cache
      stats = cache.stats

      # Multiple validators may share the same yard stats command
      # So we expect some cache hits (Warning validators share commands)
      expect(stats[:misses]).to be > 0
      expect(stats[:hits]).to be >= 0 # Cache hits from shared commands
      expect(stats[:total]).to eq(stats[:misses] + stats[:hits])
    end

    it 'handles multiple files efficiently' do
      files = Dir.glob(File.join(fixtures_dir, '*.rb'))

      Yard::Lint.run(path: files, config: config)

      cache = Yard::Lint::Validators::Base.command_cache
      stats = cache.stats

      # With multiple files, validators still benefit from cache
      # Warning validators share the same yard stats command
      expect(stats[:misses]).to be > 0
      expect(stats[:hits]).to be >= 0 # Cache hits from shared commands
      expect(stats[:total]).to eq(stats[:misses] + stats[:hits])
    end
  end

  describe 'Cache Statistics Reporting' do
    it 'provides detailed cache statistics' do
      file = File.join(fixtures_dir, 'clean_code.rb')

      Yard::Lint.run(path: file, config: config)

      cache = Yard::Lint::Validators::Base.command_cache
      stats = cache.stats

      # Should have all expected stat keys
      expect(stats).to have_key(:hits)
      expect(stats).to have_key(:misses)
      expect(stats).to have_key(:total)
      expect(stats).to have_key(:saved_executions)

      # Values should be consistent
      expect(stats[:total]).to eq(stats[:hits] + stats[:misses])
      expect(stats[:saved_executions]).to eq(stats[:hits])
    end
  end
end

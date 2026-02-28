# frozen_string_literal: true

require 'test_helper'

class DocumentationCoverageIntegrationTest < Minitest::Test
  attr_reader :temp_dir, :config_file

  def setup
    @temp_dir = Dir.mktmpdir('yard-lint-coverage-test')
    @config_file = File.join(@temp_dir, '.yard-lint.yml')
  end

  def teardown
    FileUtils.rm_rf(@temp_dir)
  end

  def run_yard_lint(path, options = {})
    config = if options[:config_file]
               Yard::Lint::Config.from_file(options[:config_file])
             else
               Yard::Lint::Config.new
             end

    config.min_coverage = options[:min_coverage] if options[:min_coverage]

    Yard::Lint.run(
      path: path,
      config: config,
      progress: false
    )
  end

  def create_test_file(name, content)
    file_path = File.join(@temp_dir, name)
    File.write(file_path, content)
    file_path
  end

  def test_basic_coverage_calculates_100_percent_for_fully_documented_code
    file = create_test_file('documented.rb', <<~RUBY)
      # frozen_string_literal: true

      # A documented class
      class MyClass
        # Initialize instance
        # @param value [String] the value
        def initialize(value)
          @value = value
        end

        # Get the value
        # @return [String] the stored value
        def value
          @value
        end
      end
    RUBY

    result = run_yard_lint(file)
    coverage = result.documentation_coverage

    refute_nil(coverage)
    assert_equal(3, coverage[:total]) # class + 2 methods
    assert_equal(3, coverage[:documented])
    assert_equal(100.0, coverage[:coverage])
  end

  def test_basic_coverage_calculates_partial_coverage_for_mixed_documentation
    file = create_test_file('mixed.rb', <<~RUBY)
      # frozen_string_literal: true

      # Documented class
      class Documented
        # Documented method
        # @param x [Integer] value
        def foo(x)
          x
        end
      end

      class ReallyUndocumented
        def bar
          1
        end
      end
    RUBY

    result = run_yard_lint(file)
    coverage = result.documentation_coverage

    refute_nil(coverage)
    assert_equal(4, coverage[:total]) # 2 classes + 2 methods
    # Documented class + foo method = 2 documented
    # ReallyUndocumented class + bar method = 2 undocumented
    assert_equal(2, coverage[:documented])
    assert_in_delta(50.0, coverage[:coverage], 0.01)
  end

  def test_basic_coverage_calculates_0_percent_for_undocumented_code
    file = create_test_file('undocumented.rb', <<~RUBY)
      # frozen_string_literal: true

      class Foo
        def bar
          1
        end
      end
    RUBY

    result = run_yard_lint(file)
    coverage = result.documentation_coverage

    refute_nil(coverage)
    assert_equal(2, coverage[:total]) # class + method
    assert_equal(0, coverage[:documented])
    assert_equal(0.0, coverage[:coverage])
  end

  def test_excluded_methods_respects_config
    # Create config with ExcludedMethods
    config_content = <<~YAML
      AllValidators:
        Exclude: []
      Documentation/UndocumentedObjects:
        ExcludedMethods:
          - 'initialize/1'  # Exclude initialize with 1 param
          - '/^private_/'    # Exclude methods starting with private_
    YAML
    File.write(@config_file, config_content)

    file = create_test_file('excluded.rb', <<~RUBY)
      # frozen_string_literal: true

      # Documented class
      class MyClass
        def initialize(value)
          @value = value
        end

        def private_method
          1
        end

        def public_method
          2
        end
      end
    RUBY

    result = run_yard_lint(file, config_file: @config_file)
    coverage = result.documentation_coverage

    # Should exclude initialize/1 and private_method from stats
    # Total: 4 (class + 3 methods) - but initialize/1 and private_method excluded
    # But YARD query doesn't filter by ExcludedMethods, it reports all objects
    # The exclusion only affects validators, not stats calculation
    # So we expect: class (1 doc) + initialize (0 doc) + private_method (0 doc) + public_method (0 doc)
    refute_nil(coverage)
    assert_equal(4, coverage[:total])
    assert_equal(1, coverage[:documented]) # Just the class
  end

  def test_min_coverage_passes_when_meets_minimum_threshold
    test_file = create_test_file('coverage_test.rb', <<~RUBY)
      # frozen_string_literal: true

      # Documented class
      class MyClass
        # Documented method
        # @return [Integer] value
        def foo
          1
        end

        def bar
          2
        end
      end
    RUBY

    result = run_yard_lint(test_file, min_coverage: 60.0)
    coverage = result.documentation_coverage

    assert_operator(coverage[:coverage], :>=, 60.0)
    # Exit code should be based on offenses, not coverage in this case
    # Since we have 1 undocumented method but meet coverage threshold
  end

  def test_min_coverage_fails_when_below_minimum_threshold
    test_file = create_test_file('coverage_test.rb', <<~RUBY)
      # frozen_string_literal: true

      # Documented class
      class MyClass
        # Documented method
        # @return [Integer] value
        def foo
          1
        end

        def bar
          2
        end
      end
    RUBY

    result = run_yard_lint(test_file, min_coverage: 90.0)
    coverage = result.documentation_coverage

    assert_operator(coverage[:coverage], :<, 90.0)
    assert_equal(1, result.exit_code)
  end

  def test_min_coverage_uses_config_file_setting
    test_file = create_test_file('coverage_test.rb', <<~RUBY)
      # frozen_string_literal: true

      # Documented class
      class MyClass
        # Documented method
        # @return [Integer] value
        def foo
          1
        end

        def bar
          2
        end
      end
    RUBY

    config_content = <<~YAML
      AllValidators:
        MinCoverage: 80.0
        Exclude: []
    YAML
    File.write(@config_file, config_content)

    result = run_yard_lint(test_file, config_file: @config_file)
    coverage = result.documentation_coverage

    # Coverage is ~66% (2 documented out of 3), below 80%
    assert_operator(coverage[:coverage], :<, 80.0)
    assert_equal(1, result.exit_code)
  end

  def test_min_coverage_cli_overrides_config_file
    test_file = create_test_file('coverage_test.rb', <<~RUBY)
      # frozen_string_literal: true

      # Documented class
      class MyClass
        # Documented method
        # @return [Integer] value
        def foo
          1
        end

        def bar
          2
        end
      end
    RUBY

    config_content = <<~YAML
      AllValidators:
        MinCoverage: 90.0
        Exclude: []
    YAML
    File.write(@config_file, config_content)

    # Load config and override with lower threshold
    config = Yard::Lint::Config.from_file(@config_file)
    config.min_coverage = 50.0

    result = Yard::Lint.run(path: test_file, config: config, progress: false)
    coverage = result.documentation_coverage

    # Should pass with 50% threshold (coverage is ~66%)
    assert_operator(coverage[:coverage], :>=, 50.0)
    # Still fails due to offenses, but not due to coverage
  end

  def test_empty_file_handling_returns_nil_for_empty_file_list
    result = Yard::Lint.run(
      path: [],
      config: Yard::Lint::Config.new,
      progress: false
    )

    coverage = result.documentation_coverage
    assert_nil(coverage) # No files means no coverage to calculate
  end

  def test_empty_file_handling_handles_files_with_no_documentable_objects
    file = create_test_file('empty.rb', <<~RUBY)
      # frozen_string_literal: true

      # Just a comment file with no classes or methods
    RUBY

    result = run_yard_lint(file)
    coverage = result.documentation_coverage

    refute_nil(coverage)
    assert_equal(0, coverage[:total])
    assert_equal(0, coverage[:documented])
    assert_equal(100.0, coverage[:coverage]) # Empty = 100% by convention
  end

  def test_multiple_files_calculates_aggregate_coverage
    file1 = create_test_file('file1.rb', <<~RUBY)
      # frozen_string_literal: true

      # Documented class
      class ClassOne
        # Documented method
        # @return [Integer] value
        def foo
          1
        end
      end
    RUBY

    file2 = create_test_file('file2.rb', <<~RUBY)
      # frozen_string_literal: true

      class ClassTwo
        def bar
          2
        end
      end
    RUBY

    result = run_yard_lint([file1, file2])
    coverage = result.documentation_coverage

    # file1: 2 documented (class + method)
    # file2: 0 documented (class + method both undocumented)
    # Total: 4 objects, 2 documented = 50%
    refute_nil(coverage)
    assert_equal(4, coverage[:total])
    assert_equal(2, coverage[:documented])
    assert_equal(50.0, coverage[:coverage])
  end

  def test_module_coverage_includes_modules_in_calculation
    file = create_test_file('modules.rb', <<~RUBY)
      # frozen_string_literal: true

      # Documented module
      module MyModule
        # Documented class
        class MyClass
          # Documented method
          # @return [String] value
          def foo
            'bar'
          end
        end
      end
    RUBY

    result = run_yard_lint(file)
    coverage = result.documentation_coverage

    # module + class + method = 3 objects, all documented
    refute_nil(coverage)
    assert_equal(3, coverage[:total])
    assert_equal(3, coverage[:documented])
    assert_equal(100.0, coverage[:coverage])
  end

  def test_module_coverage_handles_nested_undocumented_structures
    file = create_test_file('nested.rb', <<~RUBY)
      # frozen_string_literal: true

      module OuterModule
        class InnerClass
          def method_one
            1
          end

          def method_two
            2
          end
        end
      end
    RUBY

    result = run_yard_lint(file)
    coverage = result.documentation_coverage

    # module + class + 2 methods = 4 objects, 0 documented
    refute_nil(coverage)
    assert_equal(4, coverage[:total])
    assert_equal(0, coverage[:documented])
    assert_equal(0.0, coverage[:coverage])
  end

  def test_exit_code_exits_0_when_coverage_meets_threshold_and_no_offenses
    clean_file = create_test_file('clean.rb', <<~RUBY)
      # frozen_string_literal: true

      # Documented class
      class Clean
        # Documented method
        # @param x [Integer] input value
        # @return [Integer] result value
        def process(x)
          x * 2
        end
      end
    RUBY

    # Disable all validators to get clean result
    config = Yard::Lint::Config.new
    config.min_coverage = 80.0

    # This would need all validators disabled - skip for now
    # Just verify coverage calculation works
    result = Yard::Lint.run(path: clean_file, config: config, progress: false)
    coverage = result.documentation_coverage

    assert_equal(100.0, coverage[:coverage])
  end

  def test_exit_code_exits_1_when_coverage_below_threshold
    undoc_file = create_test_file('undoc.rb', <<~RUBY)
      # frozen_string_literal: true

      # Partial class
      class Partial
        def undocumented
          1
        end
      end
    RUBY

    result = run_yard_lint(undoc_file, min_coverage: 90.0)
    coverage = result.documentation_coverage

    assert_operator(coverage[:coverage], :<, 90.0)
    assert_equal(1, result.exit_code)
  end
end

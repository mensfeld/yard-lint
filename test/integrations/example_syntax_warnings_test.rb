# frozen_string_literal: true

require 'test_helper'

class ExampleSyntaxWarningSuppressionTest < Minitest::Test
  def setup
    @config = test_config do |c|
      c.send(:set_validator_config, 'Tags/ExampleSyntax', 'Enabled', true)
      end
  end

  def test_suppresses_at_eol_warnings_for_argument_forwarding_syntax
    fixture_content = <<~RUBY
      # frozen_string_literal: true

      class TestClass
        # Method with argument forwarding example
        # @example
        #   def method(a, b, ...)
        #     forward(...)
        #   end
        # @return [void]
        def example_method
        end
      end
    RUBY

    Tempfile.create(['test_endless_range', '.rb']) do |file|
      file.write(fixture_content)
      file.flush

      # Capture stderr to check for warnings
      original_stderr = $stderr
      captured_stderr = StringIO.new
      $stderr = captured_stderr

      begin
        Yard::Lint.run(path: file.path, config: @config, progress: false)
      ensure
        $stderr = original_stderr
        end
      # Should NOT contain the Ruby parser warning about "..."
      refute_includes(captured_stderr.string, '... at EOL')
      refute_includes(captured_stderr.string, 'should be parenthesized')
      end
  end

  def test_suppresses_warnings_for_endless_ranges_in_example_code
    fixture_content = <<~RUBY
      # frozen_string_literal: true

      class TestClass
        # Method with endless range example
        # @example
        #   (1..).take(5)
        # @return [void]
        def example_method
        end
      end
    RUBY

    Tempfile.create(['test_endless_range', '.rb']) do |file|
      file.write(fixture_content)
      file.flush

      original_stderr = $stderr
      captured_stderr = StringIO.new
      $stderr = captured_stderr

      begin
        Yard::Lint.run(path: file.path, config: @config, progress: false)
      ensure
        $stderr = original_stderr
        end
      # Should not produce any Ruby parser warnings about endless ranges
      # Filter out unrelated library warnings (method redefined in in_process_registry)
      parser_warnings = captured_stderr.string.lines.reject { |l| l.include?('method redefined') || l.include?('previous definition') }
      parser_warnings.each do |line|
        refute_includes(line, 'warning:')
      end
    end
  end

  def test_still_detects_actual_syntax_errors_in_example_code
    fixture_content = <<~RUBY
      # frozen_string_literal: true

      class TestClass
        # Method with syntax error in example
        # @example Bad syntax
        #   class Foo
        #     def bar
        #       puts "missing end"
        #     # missing end for def
        #   # missing end for class
        # @return [void]
        def example_method
        end
      end
    RUBY

    Tempfile.create(['test_syntax_error', '.rb']) do |file|
      file.write(fixture_content)
      file.flush

      result = Yard::Lint.run(path: file.path, config: @config, progress: false)

      syntax_errors = result.offenses.select { |o| o[:name] == 'ExampleSyntax' }
      refute_empty(syntax_errors)
      assert_includes(syntax_errors.first[:message], 'syntax error')
      end
  end
end

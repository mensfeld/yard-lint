# frozen_string_literal: true

RSpec.describe 'ExampleSyntax Warning Suppression' do
  let(:config) do
    test_config do |c|
      c.send(:set_validator_config, 'Tags/ExampleSyntax', 'Enabled', true)
    end
  end

  describe 'Ruby parser warnings' do
    it 'suppresses "... at EOL" warnings for argument forwarding syntax' do
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
          Yard::Lint.run(path: file.path, config: config, progress: false)
        ensure
          $stderr = original_stderr
        end

        # Should NOT contain the Ruby parser warning about "..."
        expect(captured_stderr.string).not_to include('... at EOL')
        expect(captured_stderr.string).not_to include('should be parenthesized')
      end
    end

    it 'suppresses warnings for endless ranges in example code' do
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
          Yard::Lint.run(path: file.path, config: config, progress: false)
        ensure
          $stderr = original_stderr
        end

        # Should not produce any Ruby parser warnings
        expect(captured_stderr.string).not_to include('warning:')
      end
    end

    it 'still detects actual syntax errors in example code' do
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

        result = Yard::Lint.run(path: file.path, config: config, progress: false)

        syntax_errors = result.offenses.select { |o| o[:name] == 'ExampleSyntax' }
        expect(syntax_errors).not_to be_empty
        expect(syntax_errors.first[:message]).to include('syntax error')
      end
    end
  end
end

# frozen_string_literal: true

require 'test_helper'

class YardLintTodoGeneratorTest < Minitest::Test
  attr_reader :test_dir, :config

  def setup
    @test_dir = Dir.mktmpdir('todo-generator-test')
    @config = Yard::Lint::Config.new
  end

  def teardown
    FileUtils.rm_rf(@test_dir)
  end

  def test_generate_with_no_violations_returns_appropriate_message
    Dir.chdir(@test_dir) do
      # Create a clean Ruby file
      FileUtils.mkdir_p('lib')
      File.write('lib/clean.rb', <<~RUBY)
        # Documentation for Foo
        class Foo
        end
      RUBY

      result = Yard::Lint::TodoGenerator.generate(
        path: 'lib',
        config: @config,
        force: false,
        exclude_limit: 15
      )

      assert_includes(result[:message], 'No offenses found')
      assert_equal(0, result[:offense_count])
      assert_equal(0, result[:validator_count])
      assert_equal(false, File.exist?('.yard-lint-todo.yml'))
    end
  end

  def test_generate_with_violations_creates_todo_yml
    Dir.chdir(@test_dir) do
      FileUtils.mkdir_p('lib')
      File.write('lib/undocumented.rb', <<~RUBY)
        class Undocumented
          def method_without_docs(param)
          end
        end
      RUBY

      result = Yard::Lint::TodoGenerator.generate(
        path: 'lib',
        config: @config,
        force: false,
        exclude_limit: 15
      )

      assert_equal(true, File.exist?('.yard-lint-todo.yml'))
      assert_operator(result[:offense_count], :>, 0)
      assert_operator(result[:validator_count], :>, 0)
    end
  end

  def test_generate_with_violations_returns_result_with_message_and_counts
    Dir.chdir(@test_dir) do
      FileUtils.mkdir_p('lib')
      File.write('lib/undocumented.rb', <<~RUBY)
        class Undocumented
          def method_without_docs(param)
          end
        end
      RUBY

      result = Yard::Lint::TodoGenerator.generate(
        path: 'lib',
        config: @config,
        force: false,
        exclude_limit: 15
      )

      assert_kind_of(Hash, result)
      assert(result.key?(:message))
      assert(result.key?(:offense_count))
      assert(result.key?(:validator_count))
      assert_includes(result[:message], 'Created .yard-lint-todo.yml')
    end
  end

  def test_generate_with_violations_creates_proper_yaml_structure
    Dir.chdir(@test_dir) do
      FileUtils.mkdir_p('lib')
      File.write('lib/undocumented.rb', <<~RUBY)
        class Undocumented
          def method_without_docs(param)
          end
        end
      RUBY

      Yard::Lint::TodoGenerator.generate(
        path: 'lib',
        config: @config,
        force: false,
        exclude_limit: 15
      )

      assert_equal(true, File.exist?('.yard-lint-todo.yml'))

      content = File.read('.yard-lint-todo.yml')
      assert_includes(content, '# This file was auto-generated')
      assert_includes(content, '# To gradually fix violations')
      assert_includes(content, 'Exclude:')

      # Parse YAML to ensure it's valid
      yaml = YAML.load_file('.yard-lint-todo.yml')
      assert_kind_of(Hash, yaml)

      # Should have at least one validator with Exclude list
      validator_keys = yaml.keys
      assert_operator(validator_keys.size, :>, 0)

      validator_keys.each do |key|
        assert(yaml[key].key?('Exclude'))
        assert_kind_of(Array, yaml[key]['Exclude'])
      end
    end
  end

  def test_generate_with_violations_creates_main_config_with_inherit_from
    Dir.chdir(@test_dir) do
      FileUtils.mkdir_p('lib')
      File.write('lib/undocumented.rb', <<~RUBY)
        class Undocumented
          def method_without_docs(param)
          end
        end
      RUBY

      Yard::Lint::TodoGenerator.generate(
        path: 'lib',
        config: @config,
        force: false,
        exclude_limit: 15
      )

      assert_equal(true, File.exist?('.yard-lint.yml'))

      config_content = YAML.load_file('.yard-lint.yml')
      assert_includes(config_content['inherit_from'], '.yard-lint-todo.yml')
    end
  end

  def test_generate_when_config_exists_adds_inherit_from
    Dir.chdir(@test_dir) do
      FileUtils.mkdir_p('lib')
      File.write('lib/undocumented.rb', <<~RUBY)
        class Undocumented
          def method_without_docs(param)
          end
        end
      RUBY

      File.write('.yard-lint.yml', <<~YAML)
        AllValidators:
          Severity: warning
      YAML

      Yard::Lint::TodoGenerator.generate(
        path: 'lib',
        config: @config,
        force: false,
        exclude_limit: 15
      )

      config_content = YAML.load_file('.yard-lint.yml')
      assert_includes(config_content['inherit_from'], '.yard-lint-todo.yml')
      assert_equal({ 'Severity' => 'warning' }, config_content['AllValidators'])
    end
  end

  def test_generate_when_config_exists_does_not_duplicate_inherit_from
    Dir.chdir(@test_dir) do
      FileUtils.mkdir_p('lib')
      File.write('lib/undocumented.rb', <<~RUBY)
        class Undocumented
          def method_without_docs(param)
          end
        end
      RUBY

      File.write('.yard-lint.yml', <<~YAML)
        AllValidators:
          Severity: warning
      YAML

      # Run twice
      Yard::Lint::TodoGenerator.generate(
        path: 'lib',
        config: @config,
        force: true,
        exclude_limit: 15
      )

      Yard::Lint::TodoGenerator.generate(
        path: 'lib',
        config: @config,
        force: true,
        exclude_limit: 15
      )

      config_content = YAML.load_file('.yard-lint.yml')
      inherit_count = config_content['inherit_from'].count('.yard-lint-todo.yml')
      assert_equal(1, inherit_count)
    end
  end

  def test_generate_raises_todo_file_exists_error_without_force
    Dir.chdir(@test_dir) do
      FileUtils.mkdir_p('lib')
      File.write('lib/test.rb', <<~RUBY)
        class Test
        end
      RUBY
      File.write('.yard-lint-todo.yml', '# existing')

      assert_raises(Yard::Lint::Errors::TodoFileExistsError) do
        Yard::Lint::TodoGenerator.generate(
          path: 'lib',
          config: @config,
          force: false,
          exclude_limit: 15
        )
      end
    end
  end

  def test_generate_overwrites_with_force_flag
    Dir.chdir(@test_dir) do
      FileUtils.mkdir_p('lib')
      File.write('lib/test.rb', <<~RUBY)
        class Test
        end
      RUBY
      File.write('.yard-lint-todo.yml', '# existing')

      result = Yard::Lint::TodoGenerator.generate(
        path: 'lib',
        config: @config,
        force: true,
        exclude_limit: 15
      )

      assert_kind_of(Hash, result)
      content = File.read('.yard-lint-todo.yml')
      refute_equal('# existing', content)
      assert_includes(content, '# This file was auto-generated')
    end
  end

  def test_generate_with_custom_exclude_limit_passes_limit_to_path_grouper
    Dir.chdir(@test_dir) do
      FileUtils.mkdir_p('lib')

      # Create multiple files to trigger grouping logic
      20.times do |i|
        File.write("lib/file_#{i}.rb", <<~RUBY)
          class File#{i}
          end
        RUBY
      end

      # Use Mocha to verify PathGrouper receives the custom limit
      Yard::Lint::PathGrouper.expects(:group).with(anything, limit: 10).at_least_once.returns({})

      Yard::Lint::TodoGenerator.generate(
        path: 'lib',
        config: @config,
        force: false,
        exclude_limit: 10
      )
    end
  end

  def test_generate_with_multiple_validators_groups_violations
    Dir.chdir(@test_dir) do
      FileUtils.mkdir_p('lib')
      File.write('lib/multi.rb', <<~RUBY)
        class Multi
          # @param invalid
          def foo(bar)
          end

          def undocumented
          end
        end
      RUBY

      Yard::Lint::TodoGenerator.generate(
        path: 'lib',
        config: @config,
        force: false,
        exclude_limit: 15
      )

      yaml = YAML.load_file('.yard-lint-todo.yml')

      # Should have multiple validators
      assert_operator(yaml.keys.size, :>, 0)

      # Each validator should have Exclude list
      yaml.each do |validator_name, validator_config|
        assert_includes(validator_name, '/')
        assert(validator_config.key?('Exclude'))
      end
    end
  end

  def test_make_relative_path_converts_absolute_path_to_relative
    Dir.chdir(@test_dir) do
      generator = Yard::Lint::TodoGenerator.new(
        path: '.',
        config: @config,
        force: false,
        exclude_limit: 15
      )

      absolute = File.join(Dir.pwd, 'lib', 'foo.rb')
      relative = generator.send(:make_relative_path, absolute)

      assert_equal('lib/foo.rb', relative)
    end
  end

  def test_make_relative_path_keeps_relative_path_unchanged
    Dir.chdir(@test_dir) do
      generator = Yard::Lint::TodoGenerator.new(
        path: '.',
        config: @config,
        force: false,
        exclude_limit: 15
      )

      relative = 'lib/foo.rb'
      result = generator.send(:make_relative_path, relative)

      assert_equal(relative, result)
    end
  end
end

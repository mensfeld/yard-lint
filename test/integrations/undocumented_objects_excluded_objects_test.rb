# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

# End-to-end coverage for the ExcludedObjects option on
# Documentation/UndocumentedObjects. Unlike ExcludedMethods (which matches only
# the trailing method name and never applies to constants), ExcludedObjects
# matches the fully-qualified object name, so it can exclude constants and be
# anchored to a full module/class path. See issue #299.
describe 'UndocumentedObjects ExcludedObjects' do
  before do
    @test_dir = Dir.mktmpdir
  end

  after do
    FileUtils.rm_rf(@test_dir) if @test_dir && File.exist?(@test_dir)
  end

  def create_test_file(filename, content)
    path = File.join(@test_dir, filename)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
    path
  end

  def build_config(excluded_objects)
    Yard::Lint::Config.new do |c|
      c.set_validator_config('Documentation/UndocumentedObjects', 'Enabled', true)
      c.set_validator_config('Documentation/UndocumentedObjects', 'ExcludedObjects', excluded_objects)
    end
  end

  def undocumented(file, config)
    result = Yard::Lint.run(path: file, config: config)
    result
      .offenses
      .select { |o| o[:name].to_s == 'UndocumentedObject' }
      .map { |o| o[:message] }
  end

  let(:source) do
    <<~RUBY
      # Input handling
      module ATui
        # Input keys
        module Input
          KEY_A_Z = 1
          KEY_0_9 = 2

          def undocumented_helper; end

          def call(event); end
        end
      end
    RUBY
  end

  it 'flags undocumented constants when nothing is excluded' do
    file = create_test_file('input.rb', source)
    messages = undocumented(file, build_config([]))

    assert_includes(messages, 'Documentation required for `ATui::Input::KEY_A_Z`')
    assert_includes(messages, 'Documentation required for `ATui::Input::KEY_0_9`')
  end

  it 'excludes constants matching a full-path regex pattern' do
    file = create_test_file('input.rb', source)
    messages = undocumented(file, build_config(['/^ATui::Input::KEY_/']))

    refute(messages.any? { |m| m.include?('KEY_A_Z') })
    refute(messages.any? { |m| m.include?('KEY_0_9') })
    # The unrelated undocumented method is still reported.
    assert_includes(messages, 'Documentation required for `ATui::Input#undocumented_helper`')
  end

  it 'excludes a single constant by its fully-qualified name' do
    file = create_test_file('input.rb', source)
    messages = undocumented(file, build_config(['ATui::Input::KEY_A_Z']))

    refute(messages.any? { |m| m.include?('KEY_A_Z') })
    assert_includes(messages, 'Documentation required for `ATui::Input::KEY_0_9`')
  end

  it 'can exclude methods by their fully-qualified name' do
    file = create_test_file('input.rb', source)
    messages = undocumented(file, build_config(['/^ATui::Input#/']))

    refute(messages.any? { |m| m.include?('#undocumented_helper') })
    assert_includes(messages, 'Documentation required for `ATui::Input::KEY_A_Z`')
  end

  it 'excludes a method by full-path arity notation only at the matching arity' do
    file = create_test_file('input.rb', source)
    # call takes 1 param; helper takes 0. The /1 pattern must exclude only call.
    messages = undocumented(file, build_config(['ATui::Input#call/1']))

    refute(messages.any? { |m| m.include?('#call') })
    assert_includes(messages, 'Documentation required for `ATui::Input#undocumented_helper`')
  end

  it 'does not exclude a method when the full-path arity does not match' do
    file = create_test_file('input.rb', source)
    # call takes 1 param, so an arity-0 pattern must not exclude it.
    messages = undocumented(file, build_config(['ATui::Input#call/0']))

    assert_includes(messages, 'Documentation required for `ATui::Input#call`')
  end

  it 'does not suppress a similarly-named class when the regex is scoped to a path' do
    file = create_test_file('cache.rb', <<~RUBY)
      class Memcached
      end
    RUBY
    # A path-anchored constant pattern must not swallow an unrelated class name.
    messages = undocumented(file, build_config(['/^ATui::Input::KEY_/']))

    assert_includes(messages, 'Documentation required for `Memcached`')
  end
end

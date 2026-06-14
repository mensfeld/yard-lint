# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

# BUG-053: Tags/InvalidTypes could never catch a misspelled class name (its
# headline use case). const_defined?("Strng") returns false, but the lenient
# check treated any syntactically valid constant name as "recognized", so every
# CamelCase typo passed. The opt-in StrictConstantNames mode (default off) flags
# CamelCase type names that are neither loaded Ruby constants nor resolvable in
# the analyzed codebase's YARD registry.
describe 'Tags/InvalidTypes StrictConstantNames' do
  attr_reader :test_dir

  before do
    @test_dir = Dir.mktmpdir
  end

  after do
    FileUtils.rm_rf(@test_dir) if @test_dir && File.exist?(@test_dir)
  end

  def write_file(name, content)
    path = File.join(@test_dir, name)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
    path
  end

  def invalid_type_offenses(path, strict:)
    config = test_config do |c|
      c.set_validator_config('Tags/InvalidTypes', 'Enabled', true)
      c.set_validator_config('Tags/InvalidTypes', 'StrictConstantNames', strict)
    end
    result = Yard::Lint.run(path: path, config: config, progress: false)
    result.offenses.select { |o| o[:name] == 'InvalidTagType' }
  end

  it 'is off by default: a misspelled class name is NOT flagged' do
    file = write_file('typo.rb', <<~RUBY)
      # @param x [Strng] a misspelled String
      # @return [void]
      def foo(x); end
    RUBY
    assert_empty(invalid_type_offenses(file, strict: false))
  end

  it 'when enabled: flags a misspelled CamelCase class name' do
    file = write_file('typo.rb', <<~RUBY)
      # @param x [Strng] a misspelled String
      # @return [void]
      def foo(x); end
    RUBY
    offenses = invalid_type_offenses(file, strict: true)
    refute_empty(offenses)
    assert_includes(offenses.first[:message], 'Strng')
  end

  it 'when enabled: does not flag a real loaded Ruby class' do
    file = write_file('real.rb', <<~RUBY)
      # @param x [String] a real class
      # @param y [Integer] another real class
      # @return [Array] yet another
      def foo(x, y); end
    RUBY
    assert_empty(invalid_type_offenses(file, strict: true))
  end

  it 'when enabled: does not flag a class defined in the analyzed codebase' do
    file = write_file('codebase.rb', <<~RUBY)
      # A widget.
      class Widget; end

      # @param w [Widget] a locally defined class
      # @return [void]
      def use(w); end
    RUBY
    assert_empty(invalid_type_offenses(file, strict: true))
  end

  it 'when enabled: does not flag the Boolean pseudo-type' do
    file = write_file('boolean.rb', <<~RUBY)
      # @param flag [Boolean] a flag
      # @return [void]
      def foo(flag); end
    RUBY
    assert_empty(invalid_type_offenses(file, strict: true))
  end

  it 'when enabled: ExtraTypes still allowlists custom type names' do
    file = write_file('extra.rb', <<~RUBY)
      # @param x [CustomThing] an allowlisted type
      # @return [void]
      def foo(x); end
    RUBY
    config = test_config do |c|
      c.set_validator_config('Tags/InvalidTypes', 'Enabled', true)
      c.set_validator_config('Tags/InvalidTypes', 'StrictConstantNames', true)
      c.set_validator_config('Tags/InvalidTypes', 'ExtraTypes', ['CustomThing'])
    end
    result = Yard::Lint.run(path: file, config: config, progress: false)
    assert_empty(result.offenses.select { |o| o[:name] == 'InvalidTagType' })
  end
end

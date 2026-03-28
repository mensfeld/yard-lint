# frozen_string_literal: true

# Regression test for https://github.com/mensfeld/yard-lint/issues/115
# Methods documented with @!attribute directive should not be flagged for
# undocumented parameters, since attribute accessors don't need @param docs.
describe 'Attribute Directive' do
  attr_reader :fixture_path, :config

  before do
    @fixture_path = File.expand_path('../fixtures/attribute_directive_examples.rb', __dir__)
    @config = test_config do |c|
      c.set_validator_config('Documentation/UndocumentedMethodArguments', 'Enabled', true)
    end
  end

  describe '@!attribute [rw] setters' do
    it 'does not flag logger= with @!attribute [rw]' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'UndocumentedMethodArgument' && o[:method_name] == 'logger='
      end

      assert_nil(offense, 'logger= with @!attribute [rw] should not be flagged')
    end

    it 'does not flag name= with @!attribute [rw]' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'UndocumentedMethodArgument' && o[:method_name] == 'name='
      end

      assert_nil(offense, 'name= with @!attribute [rw] should not be flagged')
    end

    it 'does not flag timeout= with @!attribute [rw]' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'UndocumentedMethodArgument' && o[:method_name] == 'timeout='
      end

      assert_nil(offense, 'timeout= with @!attribute [rw] should not be flagged')
    end

    it 'does not flag formatter= with complex setter body' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'UndocumentedMethodArgument' && o[:method_name] == 'formatter='
      end

      assert_nil(offense, 'formatter= with @!attribute [rw] and complex body should not be flagged')
    end

    it 'does not flag level= with @!attribute [rw] that also has @param' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'UndocumentedMethodArgument' && o[:method_name] == 'level='
      end

      assert_nil(offense, 'level= with @!attribute [rw] and @param should not be flagged')
    end
  end

  describe '@!attribute [w] write-only setter' do
    it 'does not flag password= with @!attribute [w]' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'UndocumentedMethodArgument' && o[:method_name] == 'password='
      end

      assert_nil(offense, 'password= with @!attribute [w] should not be flagged')
    end
  end

  describe '@!attribute [r] read-only getter' do
    it 'does not flag host getter with @!attribute [r]' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'UndocumentedMethodArgument' && o[:method_name] == 'host'
      end

      assert_nil(offense, 'Read-only attribute getter should not be flagged')
    end
  end

  describe '@!attribute [rw] getters' do
    it 'does not flag logger getter' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'UndocumentedMethodArgument' && o[:method_name] == 'logger'
      end

      assert_nil(offense, 'Getter for @!attribute [rw] should not be flagged')
    end
  end

  describe 'regular methods still flagged' do
    it 'flags regular_setter= without @!attribute' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'UndocumentedMethodArgument' && o[:method_name] == 'regular_setter='
      end

      refute_nil(offense, 'Regular setter without @!attribute should still be flagged')
    end

    it 'flags undocumented_param method' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'UndocumentedMethodArgument' && o[:method_name] == 'undocumented_param'
      end

      refute_nil(offense, 'Regular method with undocumented param should still be flagged')
    end

    it 'flags multiple_undocumented method' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'UndocumentedMethodArgument' && o[:method_name] == 'multiple_undocumented'
      end

      refute_nil(offense, 'Method with multiple undocumented params should be flagged')
    end

    it 'flags partially_documented method' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'UndocumentedMethodArgument' && o[:method_name] == 'partially_documented'
      end

      refute_nil(offense, 'Method with some params undocumented should be flagged')
    end
  end

  describe 'methods with proper docs not flagged' do
    it 'does not flag process method with documented params' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      offense = result.offenses.find do |o|
        o[:name] == 'UndocumentedMethodArgument' && o[:method_name] == 'process'
      end

      assert_nil(offense, 'Method with documented params should not be flagged')
    end
  end

  describe 'no false positives overall' do
    it 'only flags the expected methods' do
      result = Yard::Lint.run(path: fixture_path, config: config, progress: false)

      flagged = result.offenses
                      .select { |o| o[:name] == 'UndocumentedMethodArgument' }
                      .map { |o| o[:method_name] }
                      .sort

      expected = %w[multiple_undocumented partially_documented regular_setter= undocumented_param].sort

      assert_equal(expected, flagged, "Only non-attribute methods with missing docs should be flagged")
    end
  end
end

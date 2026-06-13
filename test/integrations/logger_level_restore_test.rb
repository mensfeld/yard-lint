# frozen_string_literal: true

# Proves that InProcessRegistry restores YARD's global logger level even when
# parsing raises. The level was set to 4 (fatal-only) and restored as the last
# statement, with no ensure, so a parse exception left the logger silenced for
# the rest of the process.
describe 'Logger level restore' do
  it 'restores the YARD logger level after a parse failure' do
    original = YARD::Logger.instance.level
    begin
      YARD::Logger.instance.level = 1

      registry = Yard::Lint::Executor::InProcessRegistry.new
      YARD.stubs(:parse).raises(RuntimeError, 'boom')

      assert_raises(RuntimeError) { registry.parse(['nonexistent.rb']) }

      assert_equal(1, YARD::Logger.instance.level, 'logger level was not restored after a parse failure')
    ensure
      YARD::Logger.instance.level = original
    end
  end
end

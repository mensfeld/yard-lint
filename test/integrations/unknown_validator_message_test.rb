# frozen_string_literal: true

# Proves that the config error for an unrecognizable validator name does not
# reference a nonexistent `--list-validators` CLI flag. yard-lint has no such
# flag; following the advice would itself produce an invalid-option error.
describe 'Unknown validator message' do
  it 'does not suggest a nonexistent --list-validators flag' do
    error = assert_raises(Yard::Lint::Errors::InvalidConfigError) do
      Yard::Lint::Config.new('Xyzzy/Plugh' => { 'Enabled' => true })
    end

    refute_includes(error.message, '--list-validators')
    assert_includes(error.message, 'wiki/Validators')
  end
end

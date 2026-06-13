# frozen_string_literal: true

# Proves that AllValidators.DiffMode.DefaultBaseRef is honored when --diff is
# used without an explicit REF. It was a documented setting that nothing read,
# so diffs always went against the auto-detected main/master.
describe 'DiffMode DefaultBaseRef' do
  it 'uses the configured DefaultBaseRef when no REF is given' do
    config = Yard::Lint::Config.new(
      'AllValidators' => { 'Exclude' => [], 'DiffMode' => { 'DefaultBaseRef' => 'develop' } }
    )

    Yard::Lint::Git.expects(:changed_files).with('develop', '.').returns([])

    Yard::Lint.send(:get_diff_files, { mode: :ref, base_ref: nil }, '.', config)
  end

  it 'still prefers an explicit REF over the configured default' do
    config = Yard::Lint::Config.new(
      'AllValidators' => { 'Exclude' => [], 'DiffMode' => { 'DefaultBaseRef' => 'develop' } }
    )

    Yard::Lint::Git.expects(:changed_files).with('main', '.').returns([])

    Yard::Lint.send(:get_diff_files, { mode: :ref, base_ref: 'main' }, '.', config)
  end
end

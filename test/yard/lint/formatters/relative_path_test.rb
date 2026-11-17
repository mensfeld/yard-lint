# frozen_string_literal: true

describe 'Yard::Lint::Formatters::RelativePath' do
  def relative(location, base_dir = '/repo')
    Yard::Lint::Formatters::RelativePath.call(location, base_dir)
  end

  it 'makes a path inside base_dir relative' do
    assert_equal('lib/foo.rb', relative('/repo/lib/foo.rb'))
  end

  it 'keeps a path outside base_dir as given' do
    assert_equal('/elsewhere/foo.rb', relative('/elsewhere/foo.rb'))
  end

  it 'makes a path under a directory whose name starts with .. relative' do
    assert_equal('..cache/foo.rb', relative('/repo/..cache/foo.rb'))
  end

  it 'does not treat a sibling directory with a common prefix as inside base_dir' do
    assert_equal('/repo2/foo.rb', relative('/repo2/foo.rb'))
  end

  it 'keeps an already relative path inside base_dir' do
    assert_equal('lib/foo.rb', relative('lib/foo.rb'))
  end

  it 'normalizes a path that leaves and re-enters base_dir' do
    assert_equal('lib/foo.rb', relative('/repo/x/../lib/foo.rb'))
  end

  it 'makes a path relative to the filesystem root' do
    assert_equal('repo/lib/foo.rb', relative('/repo/lib/foo.rb', '/'))
  end

  it 'returns an empty string for a nil location' do
    assert_equal('', relative(nil))
  end

  it 'defaults base_dir to the current directory' do
    assert_equal('lib/foo.rb', Yard::Lint::Formatters::RelativePath.call(File.join(Dir.pwd, 'lib/foo.rb')))
  end
end

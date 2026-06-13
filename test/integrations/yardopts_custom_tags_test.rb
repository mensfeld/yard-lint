# frozen_string_literal: true

require 'tmpdir'

# Proves that custom tags declared in .yardopts are not flagged as UnknownTag.
# The in-process parser called YARD.parse directly and never loaded .yardopts,
# so a project's own custom tags produced spurious Warnings/UnknownTag offenses.
describe 'yardopts custom tags' do
  it 'does not flag a custom tag declared via --tag in .yardopts' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.write('.yardopts', %(--tag yardlintcustomtag:"Custom Tag"\n))
        File.write('thing.rb', <<~RUBY)
          # A thing.
          # @yardlintcustomtag some value
          # @return [void]
          class Thing
            def x; end
          end
        RUBY

        config = test_config { |c| c.set_validator_config('Warnings/UnknownTag', 'Enabled', true) }
        result = Yard::Lint.run(path: 'thing.rb', config: config, progress: false)

        unknown = result.offenses.select { |o| o[:name] == 'UnknownTag' && o[:message].include?('yardlintcustomtag') }
        assert_empty(unknown, 'a .yardopts-declared custom tag was flagged as unknown')
      end
    end
  end
end

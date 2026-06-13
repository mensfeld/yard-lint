# frozen_string_literal: true

require 'tmpdir'

# Proves that --auto-gen-config preserves the user's existing .yard-lint.yml
# comments when adding the inherit_from line. It previously round-tripped the
# config through to_yaml, deleting all comments and reformatting the file.
describe 'auto-gen-config comment preservation' do
  it 'keeps existing comments when adding inherit_from' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.write('.yard-lint.yml', <<~YAML)
          # My project's custom yard-lint config
          # IMPORTANT: keep this comment after regeneration
          AllValidators:
            Exclude: []
        YAML
        File.write('thing.rb', "class Thing\n  def call(arg)\n    arg\n  end\nend\n")

        config = Yard::Lint::Config.from_file('.yard-lint.yml')
        Yard::Lint::TodoGenerator.generate(path: '.', config: config, force: true)

        content = File.read('.yard-lint.yml')
        assert_includes(content, 'keep this comment after regeneration', 'user comments were destroyed')
        assert_includes(content, 'inherit_from')
        assert_includes(content, '.yard-lint-todo.yml')
      end
    end
  end
end

# frozen_string_literal: true

require 'tmpdir'

# Proves that `yard-lint --update` preserves inherit_from / inherit_gem. The
# updater rebuilt the config from AllValidators + validator keys only, so the
# inheritance directives were silently dropped - resurrecting the entire
# .yard-lint-todo.yml baseline.
describe 'config --update preserves inheritance' do
  it 'keeps inherit_from across an update' do
    Dir.mktmpdir do |dir|
      config_path = File.join(dir, '.yard-lint.yml')
      File.write(config_path, <<~YAML)
        inherit_from:
          - .yard-lint-todo.yml

        AllValidators:
          Exclude: []
      YAML

      Yard::Lint::ConfigUpdater.update(path: config_path)

      content = File.read(config_path)
      assert_includes(content, 'inherit_from', 'inherit_from was dropped by --update')
      assert_includes(content, '.yard-lint-todo.yml')
    end
  end
end

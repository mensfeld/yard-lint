# frozen_string_literal: true

# Proves that .yard-lint.yml files using YAML anchors/aliases (the common
# RuboCop-style config idiom) load instead of crashing with an unrescued
# Psych::AliasesNotEnabled (Psych 4+ rejects aliases by default), and that
# malformed YAML raises the gem's own InvalidConfigError instead of leaking
# a raw Psych::SyntaxError backtrace.
describe 'YAML config loading' do
  it 'loads config files that use anchors and aliases' do
    Dir.mktmpdir do |dir|
      config_path = File.join(dir, '.yard-lint.yml')
      File.write(config_path, <<~YAML)
        AllValidators:
          Exclude: &shared_excludes
            - 'spec/**/*'

        Documentation/UndocumentedObjects:
          Exclude: *shared_excludes
      YAML

      config = Yard::Lint::Config.from_file(config_path)

      assert_equal(['spec/**/*'], config.exclude)
      assert_equal(['spec/**/*'], config.validator_exclude('Documentation/UndocumentedObjects'))
    end
  end

  it 'raises InvalidConfigError for malformed YAML instead of a raw Psych error' do
    Dir.mktmpdir do |dir|
      config_path = File.join(dir, '.yard-lint.yml')
      File.write(config_path, "AllValidators:\n  Exclude: [unclosed\n")

      error = assert_raises(Yard::Lint::Errors::InvalidConfigError) do
        Yard::Lint::Config.from_file(config_path)
      end

      assert_includes(error.message, config_path)
    end
  end
end

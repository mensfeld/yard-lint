# frozen_string_literal: true

# Proves that a missing inherit_from target is reported. Previously it was
# skipped with no warning at all - a renamed or deleted .yard-lint-todo.yml
# made the entire baseline silently evaporate, and every baselined offense
# reappeared with no indication why.
describe 'Missing inherit_from target' do
  it 'warns when an inherited config file does not exist' do
    Dir.mktmpdir do |dir|
      config_path = File.join(dir, '.yard-lint.yml')
      File.write(config_path, <<~YAML)
        inherit_from: .yard-lint-todo.yml

        AllValidators:
          FailOnSeverity: error
      YAML

      config = nil

      assert_output(nil, /\.yard-lint-todo\.yml.*not found/) do
        config = Yard::Lint::Config.from_file(config_path)
      end

      # The rest of the config must still load
      assert_equal('error', config.fail_on_severity)
    end
  end

  it 'does not warn when all inherited files exist' do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, 'base.yml'), <<~YAML)
        AllValidators:
          FailOnSeverity: error
      YAML
      config_path = File.join(dir, '.yard-lint.yml')
      File.write(config_path, "inherit_from: base.yml\n")

      assert_silent do
        Yard::Lint::Config.from_file(config_path)
      end
    end
  end
end

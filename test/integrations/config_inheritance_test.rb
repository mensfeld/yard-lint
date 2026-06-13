# frozen_string_literal: true

# Proves that diamond-shaped config inheritance loads. The loader tracked
# every file ever loaded instead of the files on the current inheritance
# path, so two configs inheriting one shared base raised a false
# CircularDependencyError although no cycle exists. True cycles must still
# be detected.
describe 'Config inheritance' do
  it 'loads diamond inheritance where two configs share a common base' do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, 'common.yml'), <<~YAML)
        AllValidators:
          FailOnSeverity: error
      YAML
      File.write(File.join(dir, 'a.yml'), <<~YAML)
        inherit_from: common.yml
        Documentation/UndocumentedObjects:
          Severity: error
      YAML
      File.write(File.join(dir, 'b.yml'), <<~YAML)
        inherit_from: common.yml
        Tags/Order:
          Severity: error
      YAML
      config_path = File.join(dir, '.yard-lint.yml')
      File.write(config_path, <<~YAML)
        inherit_from:
          - a.yml
          - b.yml
      YAML

      config = Yard::Lint::Config.from_file(config_path)

      assert_equal('error', config.fail_on_severity)
      assert_equal('error', config.validator_severity('Documentation/UndocumentedObjects'))
      assert_equal('error', config.validator_severity('Tags/Order'))
    end
  end

  it 'still detects a true inheritance cycle' do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, 'a.yml'), "inherit_from: b.yml\n")
      File.write(File.join(dir, 'b.yml'), "inherit_from: a.yml\n")
      config_path = File.join(dir, '.yard-lint.yml')
      File.write(config_path, "inherit_from: a.yml\n")

      assert_raises(Yard::Lint::Errors::CircularDependencyError) do
        Yard::Lint::Config.from_file(config_path)
      end
    end
  end
end

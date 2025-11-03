# frozen_string_literal: true

require 'rake'
require 'yard/lint/rake_task'

RSpec.describe Yard::Lint::RakeTask do
  before do
    Rake::Task.clear
  end

  describe "#initialize" do
    it 'creates a rake task with default name' do
      described_class.new

      expect(Rake::Task.task_defined?(:yard_lint)).to be true
    end

    it 'creates a rake task with custom name' do
      described_class.new(:custom_lint)

      expect(Rake::Task.task_defined?(:custom_lint)).to be true
    end

    it 'sets default values' do
      task = described_class.new

      expect(task.name).to eq(:yard_lint)
      expect(task.paths).to eq(['lib'])
      expect(task.config_file).to be_nil
      expect(task.config).to be_nil
      expect(task.fail_on_error).to be true
      expect(task.description).to eq('Run YARD documentation linter')
    end

    it 'accepts configuration block' do
      task = described_class.new do |t|
        t.paths = %w[lib app]
        t.config_file = '.custom-config.yml'
        t.fail_on_error = false
      end

      expect(task.paths).to eq(%w[lib app])
      expect(task.config_file).to eq('.custom-config.yml')
      expect(task.fail_on_error).to be false
    end
  end

  describe "task execution" do
    it 'runs without error when no offenses found' do
      allow(Yard::Lint).to receive(:run).and_return(
        instance_double(Yard::Lint::Result, clean?: true)
      )

      described_class.new
      expect { Rake::Task[:yard_lint].invoke }.to output(/No offenses found/).to_stdout
    end

    it 'displays statistics when offenses are found' do
      result = instance_double(
        Yard::Lint::Result,
        clean?: false,
        count: 3,
        statistics: { error: 1, warning: 1, convention: 1 },
        offenses: [],
        exit_code: 1
      )
      allow(Yard::Lint).to receive(:run).and_return(result)
      allow(Yard::Lint).to receive(:load_config).and_return(Yard::Lint::Config.new)

      described_class.new do |t|
        t.fail_on_error = false
      end

      expect { Rake::Task[:yard_lint].invoke }.to output(/3 offense\(s\) detected/).to_stdout
    end
  end
end

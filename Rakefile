# frozen_string_literal: true

require 'bundler/setup'
require 'bundler/gem_tasks'
require 'etc'
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/*_test.rb']
end

namespace :test do
  # Determine optimal number of parallel processes
  # Use all CPUs if less than 8, otherwise cap at 8
  def parallel_process_count
    cpus = Etc.nprocessors
    [cpus, 8].min
  end

  desc 'Run all tests in parallel'
  task :parallel do
    sh "bundle exec parallel_test -n #{parallel_process_count} test/"
  end
end

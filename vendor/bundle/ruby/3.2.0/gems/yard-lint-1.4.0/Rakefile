# frozen_string_literal: true

require 'bundler/setup'
require 'bundler/gem_tasks'
require 'etc'

namespace :spec do
  # Determine optimal number of parallel processes
  # Use all CPUs if less than 8, otherwise cap at 8
  def parallel_process_count
    cpus = Etc.nprocessors
    [cpus, 8].min
  end

  desc 'Run integration specs in parallel'
  task :integrations do
    sh "bundle exec parallel_rspec -n #{parallel_process_count} spec/integrations/"
  end

  desc 'Run all specs in parallel'
  task :parallel do
    sh "bundle exec parallel_rspec -n #{parallel_process_count} spec/"
  end
end

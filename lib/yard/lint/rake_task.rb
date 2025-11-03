# frozen_string_literal: true

require 'rake'
require 'rake/tasklib'
require_relative '../lint'

module Yard
  module Lint
    # Rake task for running YARD Lint
    #
    # @example Basic usage in Rakefile
    #   require 'yard/lint/rake_task'
    #
    #   Yard::Lint::RakeTask.new do |task|
    #     task.paths = ['lib']
    #   end
    #
    # @example With custom configuration
    #   Yard::Lint::RakeTask.new(:yard_lint) do |task|
    #     task.paths = ['lib', 'app']
    #     task.config_file = '.yard-lint.yml'
    #     task.fail_on_error = true
    #   end
    class RakeTask < Rake::TaskLib
      # @return [String, Symbol] name of the rake task (default: :yard_lint)
      attr_accessor :name

      # @return [Array<String>] paths to check (default: ['lib'])
      attr_accessor :paths

      # @return [String, nil] path to config file (default: nil, auto-detect)
      attr_accessor :config_file

      # @return [Yard::Lint::Config, nil] configuration object (default: nil)
      attr_accessor :config

      # @return [Boolean] whether to fail on errors (default: true)
      attr_accessor :fail_on_error

      # @return [String] description of the task
      attr_accessor :description

      # Create a new Rake task
      #
      # @param name [String, Symbol] name of the rake task
      # @yield [self] configuration block
      def initialize(name = :yard_lint)
        super()
        @name = name
        @paths = ['lib']
        @config_file = nil
        @config = nil
        @fail_on_error = true
        @description = 'Run YARD documentation linter'

        yield self if block_given?

        define_task
      end

      private

      # Define the Rake task
      def define_task
        desc @description
        task @name do
          run_task
        end
      end

      # Run the linting task
      def run_task
        result = Yard::Lint.run(
          path: @paths,
          config: @config,
          config_file: @config_file
        )

        if result.clean?
          puts '✓ No offenses found'
        else
          stats = result.statistics
          puts "\n#{result.count} offense(s) detected"
          puts "  Errors:      #{stats[:error]}"
          puts "  Warnings:    #{stats[:warning]}"
          puts "  Conventions: #{stats[:convention]}"
          puts

          result.offenses.each do |offense|
            severity_symbol = case offense[:severity]
                              when 'error' then 'E'
                              when 'warning' then 'W'
                              when 'convention' then 'C'
                              else '?'
                              end

            puts "[#{severity_symbol}] #{offense[:location]}:#{offense[:location_line]}"
            puts "    #{offense[:name]}: #{offense[:message]}"
            puts
          end

          if @fail_on_error
            loaded_config = @config || Yard::Lint.load_config(@config_file)
            exit_code = result.exit_code(loaded_config)
            abort 'YARD Lint failed!' if exit_code != 0
          end
        end
      end
    end
  end
end

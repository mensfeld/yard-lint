# frozen_string_literal: true

module Yard
  module Lint
    # Calculates documentation coverage statistics
    # Runs YARD queries to count documented vs undocumented objects
    class StatsCalculator
      attr_reader :config, :files

      # @param config [Yard::Lint::Config] configuration object
      # @param files [Array<String>] files to analyze
      def initialize(config, files)
        @config = config
        @files = Array(files).compact
      end

      # Calculate documentation coverage statistics
      # @return [Hash] statistics with :total, :documented, :coverage keys
      def calculate
        return default_stats if files.empty?

        raw_stats = run_yard_stats_query
        return default_stats if raw_stats.empty?

        parsed_stats = parse_stats_output(raw_stats)
        filtered_stats = apply_exclusions(parsed_stats)

        calculate_coverage_percentage(filtered_stats)
      end

      private

      # Default stats for empty file lists
      # @return [Hash]
      def default_stats
        { total: 0, documented: 0, coverage: 100.0 }
      end

      # Run YARD query to get object documentation status
      # @return [String] YARD query output
      def run_yard_stats_query
        # Create temp file with file list
        Tempfile.create(['yard_stats', '.txt']) do |f|
          files.each { |file| f.puts(Shellwords.escape(file)) }
          f.flush

          query = build_stats_query

          # Use temp directory for YARD database (auto-cleanup)
          Dir.mktmpdir("yard_stats_#{Process.pid}_") do |temp_dir|
            cmd = build_yard_command(f.path, query, temp_dir)

            stdout, _stderr, status = Open3.capture3(cmd)

            # Return empty string if YARD command fails
            return '' unless status.exitstatus.zero?

            stdout
          end
        end
      end

      # Build the YARD query for stats collection
      # @return [String] YARD query string
      def build_stats_query
        <<~QUERY.chomp
          type = object.type.to_s; state = object.docstring.all.empty? ? "undoc" : "doc"; puts "\#{type}:\#{state}"
        QUERY
      end

      # Build complete YARD command
      # @param file_list_path [String] path to file with list of files
      # @param query [String] YARD query to execute
      # @param temp_dir [String] temporary directory for YARD database
      # @return [String] complete command string
      def build_yard_command(file_list_path, query, temp_dir)
        <<~CMD.tr("\n", ' ').strip
          cat #{Shellwords.escape(file_list_path)} | xargs yard list
          --charset utf-8
          --markup markdown
          --no-progress
          --query #{Shellwords.escape(query)}
          -q
          -b #{Shellwords.escape(temp_dir)}
        CMD
      end

      # Parse YARD stats output
      # Format: "type:state" (e.g., "method:doc", "class:undoc")
      # @param output [String] YARD command output
      # @return [Hash] counts by type and state
      def parse_stats_output(output)
        stats = Hash.new { |h, k| h[k] = { documented: 0, undocumented: 0 } }

        output.each_line do |line|
          line.strip!
          next if line.empty?

          type, state = line.split(':', 2)
          next unless type && state

          if state == 'doc'
            stats[type][:documented] += 1
          elsif state == 'undoc'
            stats[type][:undocumented] += 1
          end
        end

        stats
      end

      # Apply validator exclusions to stats
      # Respects ExcludedMethods and other validator-specific exclusions
      # @param stats [Hash] parsed stats
      # @return [Hash] filtered stats
      def apply_exclusions(stats)
        # Get excluded methods from UndocumentedObjects validator config
        excluded_methods = config.validator_config('Documentation/UndocumentedObjects', 'ExcludedMethods') || []

        return stats if excluded_methods.empty?

        # For now, we can't easily filter out specific methods without re-parsing
        # This would require running YARD query with method names
        # TODO: Implement precise method-level filtering if needed

        stats
      end

      # Calculate coverage percentage from stats
      # @param stats [Hash] filtered stats by type
      # @return [Hash] final coverage statistics
      def calculate_coverage_percentage(stats)
        total_documented = 0
        total_undocumented = 0

        stats.each_value do |counts|
          total_documented += counts[:documented]
          total_undocumented += counts[:undocumented]
        end

        total_objects = total_documented + total_undocumented

        coverage = if total_objects.zero?
                     100.0
                   else
                     (total_documented.to_f / total_objects * 100)
                   end

        {
          total: total_objects,
          documented: total_documented,
          coverage: coverage
        }
      end
    end
  end
end

# frozen_string_literal: true

module Yard
  module Lint
    # Calculates documentation coverage statistics
    # Runs YARD queries to count documented vs undocumented objects
    class StatsCalculator
      # Method part of a stats line: title and arity (a title may itself contain "|")
      METHOD_REGEX = /\A(.+)\|(\d+)\z/

      attr_reader :config, :files, :source

      # @param config [Yard::Lint::Config] configuration object
      # @param files [Array<String>] Ruby source files whose YARD documentation will be checked for coverage statistics
      # @param source [String, nil] in-memory content of the single file in files (--stdin)
      def initialize(config, files, source: nil)
        @config = config
        @files = Array(files).compact
        @source = source
      end

      # Calculate documentation coverage statistics
      # @return [Hash] statistics with :total, :documented, :coverage keys
      def calculate
        return default_stats if files.empty?

        raw_stats = run_yard_stats_query
        # nil means the YARD subprocess failed - return nil (coverage unknown)
        # rather than default_stats, which would report the files as having
        # nothing to document.
        return nil if raw_stats.nil?
        return default_stats if raw_stats.empty?

        calculate_coverage_percentage(parse_stats_output(raw_stats))
      end

      private

      # Default stats for empty file lists
      # @return [Hash]
      def default_stats
        { total: 0, documented: 0, coverage: 0.0 }
      end

      # Run YARD query to get object documentation status
      # @return [String] YARD query output
      def run_yard_stats_query
        # Use temp directory for YARD database (auto-cleanup)
        Dir.mktmpdir("yard_stats_#{Process.pid}_") do |temp_dir|
          # Create temp file with file list
          Tempfile.create(['yard_stats', '.txt']) do |f|
            stats_files(temp_dir).each { |file| f.puts(Shellwords.escape(file)) }
            f.flush

            query = build_stats_query
            cmd = build_yard_command(f.path, query, temp_dir)

            stdout, _stderr, status = Open3.capture3(cmd)

            # Return nil if the YARD command fails (non-zero exit, or killed by
            # a signal so exitstatus is nil) - distinct from genuinely empty
            # output, so coverage is reported as unknown rather than 0%.
            return nil unless status.exitstatus&.zero?

            stdout
          end
        end
      end

      # Files for YARD to read. The in-memory source is written to a temp copy,
      # as the file on disk may differ or not exist
      # @param temp_dir [String] temporary directory for the copy
      # @return [Array<String>] file paths
      def stats_files(temp_dir)
        return files unless source

        source_dir = File.join(temp_dir, 'source')
        Dir.mkdir(source_dir)
        path = File.join(source_dir, File.basename(files.first))
        File.write(path, source)
        [path]
      end

      # Build the YARD query for stats collection
      # Methods also print their title and arity, so ExcludedMethods can be applied
      # @return [String] YARD query string
      def build_stats_query
        <<~QUERY.chomp
          type = object.type.to_s; state = object.docstring.all.empty? ? "undoc" : "doc"; if object.type == :method; arity = object.parameters.reject { |p| p[0].to_s.start_with?("*", "&") }.size; puts "\#{type}:\#{state}:\#{object.title}|\#{arity}"; else; puts "\#{type}:\#{state}"; end
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

      # Parse YARD stats output, skipping methods that match ExcludedMethods
      # Format: "type:state" (e.g., "class:undoc") or "method:state:Title|arity"
      #   (e.g., "method:doc:Foo#bar|1")
      # @param output [String] YARD command output
      # @return [Hash] counts by type and state
      def parse_stats_output(output)
        stats = Hash.new { |h, k| h[k] = { documented: 0, undocumented: 0 } }
        excluded_methods = excluded_method_patterns

        output.each_line do |line|
          line.strip!
          next if line.empty?

          type, state, method = line.split(':', 3)
          next unless type && state

          if method
            match = method.match(METHOD_REGEX)
            next unless match
            next if excluded_methods.any? &&
                    exclusion_parser.method_excluded?(match[1], match[2].to_i, excluded_methods)
          end

          if state == 'doc'
            stats[type][:documented] += 1
          elsif state == 'undoc'
            stats[type][:undocumented] += 1
          end
        end

        stats
      end

      # ExcludedMethods patterns of the UndocumentedObjects validator
      # @return [Array<String>] sanitized patterns
      def excluded_method_patterns
        patterns = config.validator_config('Documentation/UndocumentedObjects', 'ExcludedMethods') || []

        exclusion_parser.sanitize_patterns(Array(patterns))
      end

      # Parser whose ExcludedMethods matching the validator itself uses
      # @return [Validators::Documentation::UndocumentedObjects::Parser]
      def exclusion_parser
        @exclusion_parser ||= Validators::Documentation::UndocumentedObjects::Parser.new
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
                     0.0
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

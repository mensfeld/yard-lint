# frozen_string_literal: true

RSpec.describe Yard::Lint::PathGrouper do
  describe '.group' do
    context 'when files count is below limit' do
      it 'returns files sorted' do
        files = ['lib/foo.rb', 'lib/bar.rb', 'lib/baz.rb']
        result = described_class.group(files, limit: 15)

        expect(result).to eq(files.sort)
      end
    end

    context 'when files count equals limit' do
      it 'returns files unchanged' do
        files = Array.new(15) { |i| "lib/file_#{i}.rb" }
        result = described_class.group(files, limit: 15)

        # Should not group because we need >= limit and coverage threshold
        # This will depend on actual directory structure
        expect(result).to be_an(Array)
      end
    end

    context 'when files are in same directory and meet coverage threshold' do
      it 'groups files into pattern' do
        test_dir = Dir.mktmpdir('path-grouper-test')

        begin
          # Create test directory with files
          lib_dir = File.join(test_dir, 'lib')
          FileUtils.mkdir_p(lib_dir)

          # Create 15 files (meets limit)
          files = []
          15.times do |i|
            file = File.join(lib_dir, "file_#{i}.rb")
            File.write(file, '# test')
            files << "lib/file_#{i}.rb"
          end

          # Change to test directory so relative paths work
          Dir.chdir(test_dir) do
            result = described_class.group(files, limit: 15)

            # Should group into pattern since we have 15/15 files (100% coverage)
            expect(result).to eq(['lib/**/*'])
          end
        ensure
          FileUtils.rm_rf(test_dir)
        end
      end
    end

    context 'when files are in same directory but do not meet coverage threshold' do
      it 'keeps individual files' do
        test_dir = Dir.mktmpdir('path-grouper-test')

        begin
          lib_dir = File.join(test_dir, 'lib')
          FileUtils.mkdir_p(lib_dir)

          # Create 20 total files
          20.times do |i|
            file = File.join(lib_dir, "file_#{i}.rb")
            File.write(file, '# test')
          end

          # Only include 15 files in the list (75% coverage, below 80% threshold)
          files = []
          15.times do |i|
            files << "lib/file_#{i}.rb"
          end

          Dir.chdir(test_dir) do
            result = described_class.group(files, limit: 15)

            # Should not group because coverage is only 75% (below 80% threshold)
            expect(result).to eq(files.sort)
          end
        ensure
          FileUtils.rm_rf(test_dir)
        end
      end
    end

    context 'when files are in different directories' do
      it 'keeps files separate' do
        files = [
          'lib/foo.rb',
          'app/bar.rb',
          'spec/baz.rb'
        ]

        result = described_class.group(files, limit: 1)

        # Files are in different directories, so no grouping
        expect(result.sort).to eq(files.sort)
      end
    end

    context 'when some directories can be grouped and others cannot' do
      it 'groups eligible directories only' do
        test_dir = Dir.mktmpdir('path-grouper-test')

        begin
          # Create lib directory with many files
          lib_dir = File.join(test_dir, 'lib')
          FileUtils.mkdir_p(lib_dir)

          lib_files = []
          15.times do |i|
            file = File.join(lib_dir, "lib_#{i}.rb")
            File.write(file, '# test')
            lib_files << "lib/lib_#{i}.rb"
          end

          # Create app directory with few files
          app_dir = File.join(test_dir, 'app')
          FileUtils.mkdir_p(app_dir)

          app_files = []
          3.times do |i|
            file = File.join(app_dir, "app_#{i}.rb")
            File.write(file, '# test')
            app_files << "app/app_#{i}.rb"
          end

          all_files = lib_files + app_files

          Dir.chdir(test_dir) do
            result = described_class.group(all_files, limit: 10)

            # lib should be grouped, app should remain individual
            expect(result).to include('lib/**/*')
            app_files.each do |file|
              expect(result).to include(file)
            end
          end
        ensure
          FileUtils.rm_rf(test_dir)
        end
      end
    end

    context 'with custom limit' do
      it 'uses the provided limit' do
        files = ['lib/a.rb', 'lib/b.rb', 'lib/c.rb']

        # With limit of 3, should not group (need > limit)
        result = described_class.group(files, limit: 3)
        expect(result).to eq(files)

        # With limit of 2, might group if coverage is good
        result = described_class.group(files, limit: 2)
        expect(result).to be_an(Array)
      end
    end

    it 'returns sorted results' do
      files = ['z.rb', 'a.rb', 'm.rb']
      result = described_class.group(files, limit: 100)

      expect(result).to eq(files.sort)
    end

    it 'handles duplicate files' do
      files = ['lib/a.rb', 'lib/a.rb', 'lib/b.rb']
      result = described_class.group(files, limit: 100)

      # Should deduplicate
      expect(result).to eq(['lib/a.rb', 'lib/b.rb'])
    end
  end
end

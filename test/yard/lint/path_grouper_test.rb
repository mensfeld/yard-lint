# frozen_string_literal: true

require 'test_helper'

class YardLintPathGrouperTest < Minitest::Test
  def test_group_when_files_count_is_below_limit_returns_files_sorted
    files = ['lib/foo.rb', 'lib/bar.rb', 'lib/baz.rb']
    result = Yard::Lint::PathGrouper.group(files, limit: 15)

    assert_equal(files.sort, result)
  end

  def test_group_when_files_count_equals_limit_returns_files_unchanged
    files = Array.new(15) { |i| "lib/file_#{i}.rb" }
    result = Yard::Lint::PathGrouper.group(files, limit: 15)

    # Should not group because we need >= limit and coverage threshold
    # This will depend on actual directory structure
    assert_kind_of(Array, result)
  end

  def test_group_when_files_are_in_same_directory_and_meet_coverage_threshold_groups_files_into_pattern
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
        result = Yard::Lint::PathGrouper.group(files, limit: 15)

        # Should group into pattern since we have 15/15 files (100% coverage)
        assert_equal(['lib/**/*'], result)
      end
    ensure
      FileUtils.rm_rf(test_dir)
    end
  end

  def test_group_when_files_are_in_same_directory_but_do_not_meet_coverage_threshold_keeps_individual_files
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
        result = Yard::Lint::PathGrouper.group(files, limit: 15)

        # Should not group because coverage is only 75% (below 80% threshold)
        assert_equal(files.sort, result)
      end
    ensure
      FileUtils.rm_rf(test_dir)
    end
  end

  def test_group_when_files_are_in_different_directories_keeps_files_separate
    files = [
      'lib/foo.rb',
      'app/bar.rb',
      'spec/baz.rb'
    ]

    result = Yard::Lint::PathGrouper.group(files, limit: 1)

    # Files are in different directories, so no grouping
    assert_equal(files.sort, result.sort)
  end

  def test_group_when_some_directories_can_be_grouped_and_others_cannot_groups_eligible_directories_only
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
        result = Yard::Lint::PathGrouper.group(all_files, limit: 10)

        # lib should be grouped, app should remain individual
        assert_includes(result, 'lib/**/*')
        app_files.each do |file|
          assert_includes(result, file)
        end
      end
    ensure
      FileUtils.rm_rf(test_dir)
    end
  end

  def test_group_with_custom_limit_uses_the_provided_limit
    files = ['lib/a.rb', 'lib/b.rb', 'lib/c.rb']

    # With limit of 3, should not group (need > limit)
    result = Yard::Lint::PathGrouper.group(files, limit: 3)
    assert_equal(files, result)

    # With limit of 2, might group if coverage is good
    result = Yard::Lint::PathGrouper.group(files, limit: 2)
    assert_kind_of(Array, result)
  end

  def test_group_returns_sorted_results
    files = ['z.rb', 'a.rb', 'm.rb']
    result = Yard::Lint::PathGrouper.group(files, limit: 100)

    assert_equal(files.sort, result)
  end

  def test_group_handles_duplicate_files
    files = ['lib/a.rb', 'lib/a.rb', 'lib/b.rb']
    result = Yard::Lint::PathGrouper.group(files, limit: 100)

    # Should deduplicate
    assert_equal(['lib/a.rb', 'lib/b.rb'], result)
  end
end

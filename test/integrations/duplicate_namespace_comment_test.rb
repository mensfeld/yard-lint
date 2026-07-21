# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

describe 'Documentation/DuplicateNamespaceComment' do
  attr_reader :dirs

  before { @dirs = [] }
  after { @dirs.each { |dir| FileUtils.rm_rf(dir) } }

  # Lint the given file path(s) and return only this validator's offenses.
  # @param paths [String, Array<String>] file path(s) to lint
  # @return [Array<Hash>] offenses produced by Documentation/DuplicateNamespaceComment
  def offenses_for(paths)
    Yard::Lint
      .run(path: Array(paths), config: test_config, progress: false)
      .offenses
      .select { |offense| offense[:validator] == 'Documentation/DuplicateNamespaceComment' }
  end

  # Write {filename => source} into a fresh tmp dir, in order, and return the paths.
  # @param files [Hash{String => String}] filename to Ruby source
  # @return [Array<String>] absolute paths, in insertion order
  def write_files(files)
    dir = Dir.mktmpdir
    @dirs << dir
    files.map do |name, content|
      path = File.join(dir, name)
      File.write(path, content)
      path
    end
  end

  # @param name [String] fixture file name
  # @return [String] absolute path to a committed fixture
  def fixture(name)
    File.expand_path("fixtures/#{name}", __dir__)
  end

  describe 'committed fixtures' do
    let(:documented_pair) do
      [fixture('duplicate_namespace_a.rb'), fixture('duplicate_namespace_b.rb')]
    end

    it 'flags a namespace documented in two files' do
      offenses = offenses_for(documented_pair)

      assert_equal(1, offenses.size)
      assert_equal('DuplicateNamespaceComment', offenses.first[:name])
      assert_includes(offenses.first[:message], '`DuplicateNs`')
    end

    it 'reports the same single offense regardless of file order' do
      assert_equal(1, offenses_for(documented_pair).size)
      assert_equal(1, offenses_for(documented_pair.reverse).size)
    end

    it 'lists both documented locations in the message' do
      message = offenses_for(documented_pair).first[:message]

      assert_includes(message, 'duplicate_namespace_a.rb')
      assert_includes(message, 'duplicate_namespace_b.rb')
    end

    it 'does not flag leaf classes defined in a single file' do
      messages = offenses_for(documented_pair).map { |offense| offense[:message] }

      refute(messages.any? { |message| message.include?('`DuplicateNs::Leaf`') })
      refute(messages.any? { |message| message.include?('`DuplicateNs::Other`') })
    end

    it 'does not flag a namespace documented in only one of the files' do
      pair = [fixture('duplicate_namespace_a.rb'), fixture('duplicate_namespace_c.rb')]

      assert_empty(offenses_for(pair))
    end
  end

  describe 'detection details' do
    it 'marks differing docstrings as a content-losing conflict' do
      paths = write_files(
        'a.rb' => "# frozen_string_literal: true\n\n# First description.\nmodule Shared\nend\n",
        'b.rb' => "# frozen_string_literal: true\n\n# Second, different description.\nmodule Shared\nend\n"
      )

      message = offenses_for(paths).first[:message]

      assert_includes(message, 'docstrings differ')
    end

    it 'flags identical duplicated docstrings without a conflict note' do
      doc = "# frozen_string_literal: true\n\n# Same description.\nmodule Shared\nend\n"
      paths = write_files('a.rb' => doc, 'b.rb' => doc)

      offenses = offenses_for(paths)

      assert_equal(1, offenses.size)
      refute_includes(offenses.first[:message], 'docstrings differ')
    end

    it 'produces a warning severity offense' do
      doc = "# Description here.\nmodule Shared\nend\n"
      paths = write_files('a.rb' => doc, 'b.rb' => doc)

      assert_equal('warning', offenses_for(paths).first[:severity])
    end

    it 'flags classes reopened and documented across files' do
      paths = write_files(
        'a.rb' => "# A shared class.\nclass Shared\nend\n",
        'b.rb' => "# A shared class, reopened.\nclass Shared\nend\n"
      )

      offenses = offenses_for(paths)

      assert_equal(1, offenses.size)
      assert_includes(offenses.first[:message], '`Shared`')
    end

    it 'counts every documented file' do
      doc = "# Shared description.\nmodule Shared\nend\n"
      paths = write_files('a.rb' => doc, 'b.rb' => doc, 'c.rb' => doc)

      offenses = offenses_for(paths)

      assert_equal(1, offenses.size)
      assert_includes(offenses.first[:message], 'documented in 3 files')
    end

    it 'does not count magic comments as documentation' do
      src = "# frozen_string_literal: true\nmodule Shared\nend\n"
      paths = write_files('a.rb' => src, 'b.rb' => src)

      assert_empty(offenses_for(paths))
    end

    it 'does not count a blank-line-detached comment as documentation' do
      src = "# Detached comment.\n\nmodule Shared\nend\n"
      paths = write_files('a.rb' => src, 'b.rb' => src)

      assert_empty(offenses_for(paths))
    end

    it 'does not count rubocop directives as documentation' do
      src = "# rubocop:disable Style/Documentation\nmodule Shared\nend\n"
      paths = write_files('a.rb' => src, 'b.rb' => src)

      assert_empty(offenses_for(paths))
    end

    it 'does not flag a namespace documented in exactly one file' do
      paths = write_files(
        'a.rb' => "# Documented once.\nmodule Shared\nend\n",
        'b.rb' => "module Shared\nend\n"
      )

      assert_empty(offenses_for(paths))
    end
  end
end

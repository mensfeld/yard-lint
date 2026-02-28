# frozen_string_literal: true

require_relative 'lib/yard/lint/version'

Gem::Specification.new do |spec|
  spec.name = 'yard-lint'
  spec.version = Yard::Lint::VERSION
  spec.authors = ['Maciej Mensfeld']
  spec.email = ['maciej@mensfeld.pl']

  spec.summary = 'YARD documentation linter and validator'
  spec.description = 'A comprehensive linter for YARD documentation that checks for ' \
                     'undocumented code, invalid tags, incorrect tag ordering, and more.'
  spec.homepage = 'https://github.com/mensfeld/yard-lint'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/mensfeld/yard-lint'
  spec.metadata['changelog_uri'] = 'https://github.com/mensfeld/yard-lint/blob/master/CHANGELOG.md'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.end_with?('.gem') ||
        f.start_with?(
          *%w[Gemfile .gitignore test/ .github/ .rubocop.yml .yard-lint.yml]
        )
    end
  end
  spec.bindir = 'bin'
  spec.executables = spec.files.grep(%r{\Abin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'yard', '~> 0.9'
  spec.add_dependency 'zeitwerk', '~> 2.6'
end

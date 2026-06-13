# -*- encoding: utf-8 -*-
# stub: yard-lint 1.4.0 ruby lib

Gem::Specification.new do |s|
  s.name = "yard-lint".freeze
  s.version = "1.4.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/mensfeld/yard-lint/blob/master/CHANGELOG.md", "homepage_uri" => "https://github.com/mensfeld/yard-lint", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/mensfeld/yard-lint" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Maciej Mensfeld".freeze]
  s.date = "1980-01-02"
  s.description = "A comprehensive linter for YARD documentation that checks for undocumented code, invalid tags, incorrect tag ordering, and more.".freeze
  s.email = ["maciej@mensfeld.pl".freeze]
  s.executables = ["yard-lint".freeze]
  s.files = ["bin/yard-lint".freeze]
  s.homepage = "https://github.com/mensfeld/yard-lint".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.2.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "YARD documentation linter and validator".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<yard>.freeze, ["~> 0.9"])
  s.add_runtime_dependency(%q<zeitwerk>.freeze, ["~> 2.6"])
end

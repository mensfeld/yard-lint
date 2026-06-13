# -*- encoding: utf-8 -*-
# stub: standard-minitest 1.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "standard-minitest".freeze
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/kirillplatonov/standard-minitest/blob/main/CHANGELOG.md", "default_lint_roller_plugin" => "Standard::Minitest::Plugin", "homepage_uri" => "https://github.com/kirillplatonov/standard-minitest", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/kirillplatonov/standard-minitest" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Kirill Platonov".freeze]
  s.bindir = "exe".freeze
  s.date = "2023-05-23"
  s.email = ["mail@kirillplatonov.com".freeze]
  s.homepage = "https://github.com/kirillplatonov/standard-minitest".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "A Standard Ruby plugin that configures rubocop-minitest".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<lint_roller>.freeze, ["~> 1.0"])
  s.add_runtime_dependency(%q<rubocop-minitest>.freeze, [">= 0"])
end

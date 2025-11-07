# Changelog

## 0.2.1 (2025-11-07)
- Release to validate Trusted Publishing flow. 

## 0.2.0 (2025-11-07)

- Initial release of YARD-Lint gem
- Comprehensive YARD documentation validation
- CLI tool (`yard-lint`) for running linter
- Detects undocumented classes, modules, and methods
- Validates parameter documentation
- Validates tag type definitions
- Enforces tag ordering conventions
- Validates boolean method documentation
- Detects YARD warnings (unknown tags, invalid directives, etc.)
- JSON and text output formats
- Configurable tag ordering and extra type definitions
- Ruby API for programmatic usage
- Result object with offense categorization
- Three severity levels: error, warning, convention
- YAML configuration file support (`.yard-lint.yml`)
- Automatic configuration file discovery
- File exclusion patterns with glob support
- Configurable exit code based on severity level
- Quiet mode (`--quiet`) for minimal output
- Statistics summary (`--stats`)
- @api tag validation with configurable allowed APIs
- @abstract method validation
- @option hash documentation validation
- Zeitwerk for automatic code loading

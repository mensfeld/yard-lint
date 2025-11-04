# YARD-Lint

A comprehensive linter for YARD documentation that helps you maintain clean, consistent, and complete documentation in your Ruby projects.

## Features

YARD-Lint validates your YARD documentation for:

- **Undocumented code**: Classes, modules, methods, and constants without documentation
- **Missing parameter documentation**: Methods with undocumented parameters
- **Invalid tag types**: Type definitions that aren't valid Ruby classes or allowed defaults
- **Invalid tag ordering**: Tags that don't follow your specified order
- **Boolean method documentation**: Question mark methods missing return type documentation
- **API tag validation**: Enforce @api tags on public objects and validate API values
- **Abstract method validation**: Ensure @abstract methods don't have real implementations
- **Option hash documentation**: Validate that methods with options parameters have @option tags
- **YARD warnings**: Unknown tags, invalid directives, duplicated parameter names, and more

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'yard-lint'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install yard-lint
```

## Usage

### Command Line

Basic usage:

```bash
yard-lint lib/
```

With options:

```bash
# Use a specific config file
yard-lint --config config/yard-lint.yml lib/

# Output as JSON
yard-lint --format json lib/ > report.json

# Quiet mode (only show summary)
yard-lint --quiet lib/

# Show statistics
yard-lint --stats lib/
```

## Configuration

YARD-Lint is configured via a `.yard-lint.yml` configuration file (similar to `.rubocop.yml`).

### Configuration File

Create a `.yard-lint.yml` file in your project root using the **new hierarchical format** (similar to RuboCop):

```yaml
# .yard-lint.yml
# Global settings for all validators
AllValidators:
  # YARD command-line options
  YardOptions:
    - --private
    - --protected

  # Global file exclusion patterns
  Exclude:
    - '\.git'
    - 'vendor/**/*'
    - 'node_modules/**/*'
    - 'spec/**/*'

  # Exit code behavior (error, warning, convention, never)
  FailOnSeverity: warning

# Documentation validators - checks for missing documentation
Documentation:
  Enabled: true

Documentation/UndocumentedObjects:
  Description: 'Checks for classes, modules, and methods without documentation.'
  Enabled: true
  Severity: warning

Documentation/UndocumentedMethodArguments:
  Description: 'Checks for method parameters without @param tags.'
  Enabled: true
  Severity: warning

# Tags validators - validates YARD tag quality
Tags:
  Enabled: true

Tags/Order:
  Description: 'Enforces consistent ordering of YARD tags.'
  Enabled: true
  Severity: convention
  EnforcedOrder:
    - param
    - option
    - return
    - raise
    - example

Tags/InvalidTypes:
  Description: 'Validates type definitions in @param, @return, @option tags.'
  Enabled: true
  Severity: warning
  ValidatedTags:
    - param
    - option
    - return
  ExtraTypes:
    - CustomType
    - MyType

Tags/ApiTags:
  Description: 'Enforces @api tags on public objects.'
  Enabled: false  # Opt-in validator
  Severity: warning
  AllowedApis:
    - public
    - private
    - internal

Tags/OptionTags:
  Description: 'Requires @option tags for methods with options parameters.'
  Enabled: true
  Severity: warning

# Warnings validators - catches YARD parser errors (always enabled)
Warnings:
  Enabled: true
  Severity: error

# Semantic validators - validates code semantics
Semantic:
  Enabled: true

Semantic/AbstractMethods:
  Description: 'Ensures @abstract methods do not have real implementations.'
  Enabled: true
  Severity: warning
```

#### Key Features

- **RuboCop-like structure**: Organized by validator departments (Documentation, Tags, Warnings, Semantic)
- **Per-validator control**: Enable/disable and configure each validator independently
- **Custom severity**: Override severity levels per validator
- **Per-validator exclusions**: Add validator-specific file exclusions (in addition to global ones)
- **Inheritance support**: Use `inherit_from` and `inherit_gem` to share configurations
- **Self-documenting**: Each validator can include a `Description` field

#### Configuration Discovery

YARD-Lint will automatically search for `.yard-lint.yml` in the current directory and parent directories.

You can specify a different config file:

```bash
yard-lint --config path/to/config.yml lib/
```

#### Configuration Inheritance

Share configurations across projects using inheritance (like RuboCop):

```yaml
# Inherit from local files
inherit_from:
  - .yard-lint_todo.yml
  - ../.yard-lint.yml

# Inherit from gems
inherit_gem:
  my-company-style: .yard-lint.yml

# Your project-specific overrides
Documentation/UndocumentedObjects:
  Exclude:
    - 'lib/legacy/**/*'
```

### Available Validators

#### Documentation Validators

- **Documentation/UndocumentedObjects**: Checks for classes, modules, and methods without documentation
- **Documentation/UndocumentedMethodArguments**: Checks for method parameters without `@param` tags
- **Documentation/UndocumentedBooleanMethods**: Checks that question mark methods document their boolean return

#### Tags Validators

- **Tags/Order**: Enforces consistent ordering of YARD tags (configure with `EnforcedOrder`)
- **Tags/InvalidTypes**: Validates type definitions in `@param`, `@return`, `@option` tags (configure with `ValidatedTags` and `ExtraTypes`)
- **Tags/ApiTags**: Enforces `@api` tags on public objects (opt-in, configure with `AllowedApis`)
- **Tags/OptionTags**: Requires `@option` tags for methods with options parameters

#### Warnings Validators

- **Warnings/UnknownTag**: Detects unknown YARD tags
- **Warnings/UnknownDirective**: Detects unknown YARD directives
- **Warnings/InvalidTagFormat**: Detects malformed tag syntax
- **Warnings/InvalidDirectiveFormat**: Detects malformed directive syntax
- **Warnings/DuplicatedParameterName**: Detects duplicate `@param` tags
- **Warnings/UnknownParameterName**: Detects `@param` tags for non-existent parameters

#### Semantic Validators

- **Semantic/AbstractMethods**: Ensures `@abstract` methods don't have real implementations

### Global Configuration Options

- **AllValidators/YardOptions**: Array of YARD command-line options (e.g., `--private`, `--protected`)
- **AllValidators/Exclude**: Array of glob patterns to exclude from linting
- **AllValidators/FailOnSeverity**: Exit with error code for this severity level and above (`error`, `warning`, `convention`, `never`)

## Severity Levels

YARD-Lint categorizes offenses into three severity levels:

- **error**: Critical issues (unknown tags, invalid formats, malformed syntax)
- **warning**: Missing documentation, invalid type definitions, semantic issues
- **convention**: Style issues (tag ordering, formatting)

## Integration with CI

### GitHub Actions

```yaml
- name: Run YARD Lint
  run: |
    bundle exec yard-lint lib/
```

### With RuboCop

You can run YARD-Lint alongside RuboCop in your CI pipeline:

```yaml
- name: Run Linters
  run: |
    bundle exec rubocop
    bundle exec yard-lint lib/
```

## CLI Options

YARD-Lint supports the following command-line options:

```bash
yard-lint [options] PATH

Options:
  -c, --config FILE     Path to config file (default: .yard-lint.yml)
  -f, --format FORMAT   Output format (text, json)
  -q, --quiet           Quiet mode (only show summary)
      --stats           Show statistics summary
  -v, --version         Show version
  -h, --help            Show this help
```

All configuration (tag order, exclude patterns, severity levels, validator settings) should be defined in `.yard-lint.yml`.

## Examples

### Check a directory

```bash
yard-lint lib/
```

### Check a single file

```bash
yard-lint lib/my_class.rb
```

### Quiet mode with statistics

```bash
yard-lint --quiet --stats lib/
```

### JSON output

```bash
yard-lint --format json lib/ > report.json
```

### Use custom config file

```bash
yard-lint --config config/yard-lint.yml lib/
```

### Configure fail-on-severity

Add to `.yard-lint.yml`:
```yaml
AllValidators:
  FailOnSeverity: error  # Only fail on errors, not warnings
```

### Enable @api tag validation

Add to `.yard-lint.yml`:
```yaml
Tags/ApiTags:
  Enabled: true
  AllowedApis:
    - public
    - private
```

This will enforce that all public classes, modules, and methods have an `@api` tag:

```ruby
# Good
# @api public
class MyClass
  # @api public
  def public_method
  end

  # @api private
  def internal_helper
  end
end

# Bad - missing @api tags
class AnotherClass
  def some_method
  end
end
```

### @abstract method validation (enabled by default)

This validator ensures abstract methods don't have real implementations. It's **enabled by default**. To disable it, add to `.yard-lint.yml`:

```yaml
Semantic/AbstractMethods:
  Enabled: false
```

Examples:

```ruby
# Good
# @abstract
def process
  raise NotImplementedError
end

# Bad - @abstract method has implementation
# @abstract
def process
  puts "This shouldn't be here"
  do_something
end
```

### @option tag validation (enabled by default)

This validator ensures that methods with options parameters document them. It's **enabled by default**. To disable it, add to `.yard-lint.yml`:

```yaml
Tags/OptionTags:
  Enabled: false
```

Examples:

```ruby
# Good
# @param name [String] the name
# @param options [Hash] configuration options
# @option options [Boolean] :enabled Whether to enable the feature
# @option options [Integer] :timeout Timeout in seconds
def configure(name, options = {})
end

# Bad - missing @option tags
# @param name [String] the name
# @param options [Hash] configuration options
def configure(name, options = {})
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed list of changes in each version.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mensfeld/yard-lint.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

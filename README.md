# YARD-Lint

A comprehensive linter for YARD documentation that helps you maintain clean, consistent, and complete documentation in your Ruby and Ruby on Rails projects.

## Why Documentation Quality Matters More Than Ever

Accurate documentation isn't just for human developers anymore. [Research shows](https://arxiv.org/html/2404.03114) that incorrect documentation reduces AI assistant success rates up to 50% (from 44.7% to 22.1%). [Enterprise studies](https://arxiv.org/html/2501.13282v1) with 400+ developers found well-documented code achieves 30%+ AI acceptance rates versus 14-20% for poorly documented code.

**The problem:** Documentation drifts as code changes-parameters get renamed, return types change, but docs stay stale. This doesn't just confuse developers; it trains AI coding assistants to generate confidently wrong code.

**The solution:** YARD-Lint automatically validates your YARD documentation stays synchronized with your code, ensuring both human developers and AI tools have accurate context.

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
```

## Configuration

YARD-Lint is configured via a `.yard-lint.yml` configuration file (similar to `.rubocop.yml`).

### Configuration File

Create a `.yard-lint.yml` file in your project root:

```yaml
# .yard-lint.yml
# Global settings for all validators
AllValidators:
  # YARD command-line options (applied to all validators by default)
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

# Individual validator configuration
Documentation/UndocumentedObjects:
  Description: 'Checks for classes, modules, and methods without documentation.'
  Enabled: true
  Severity: warning
  # Allow initialize methods with no parameters to remain undocumented (default: true)
  AllowEmptyInitialize: true

Documentation/UndocumentedMethodArguments:
  Description: 'Checks for method parameters without @param tags.'
  Enabled: true
  Severity: warning

Documentation/UndocumentedBooleanMethods:
  Description: 'Checks that question mark methods document their boolean return.'
  Enabled: true
  Severity: warning

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

# Warnings validators - catches YARD parser errors
Warnings/UnknownTag:
  Description: 'Detects unknown YARD tags.'
  Enabled: true
  Severity: error

Warnings/UnknownDirective:
  Description: 'Detects unknown YARD directives.'
  Enabled: true
  Severity: error

Warnings/InvalidTagFormat:
  Description: 'Detects malformed tag syntax.'
  Enabled: true
  Severity: error

Warnings/InvalidDirectiveFormat:
  Description: 'Detects malformed directive syntax.'
  Enabled: true
  Severity: error

Warnings/DuplicatedParameterName:
  Description: 'Detects duplicate @param tags.'
  Enabled: true
  Severity: error

Warnings/UnknownParameterName:
  Description: 'Detects @param tags for non-existent parameters.'
  Enabled: true
  Severity: error

Semantic/AbstractMethods:
  Description: 'Ensures @abstract methods do not have real implementations.'
  Enabled: true
  Severity: warning
```

#### Key Features

- **Per-validator control**: Enable/disable and configure each validator independently
- **Custom severity**: Override severity levels per validator
- **Per-validator exclusions**: Add validator-specific file exclusions (in addition to global ones)
- **Per-validator YardOptions**: Override YARD options for specific validators if needed
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

#### Per-Validator Exclusions

You can exclude specific files from individual validators while still checking them with other validators. This is useful when you want different validators to apply to different parts of your codebase.

**Example: Skip type checking in legacy code**

```yaml
# .yard-lint.yml
AllValidators:
  Exclude:
    - 'vendor/**/*'

# Exclude legacy files from type validation only
Tags/InvalidTypes:
  Exclude:
    - 'lib/legacy/**/*'
    - 'lib/deprecated/*.rb'

# But still check for undocumented methods in those files
Documentation/UndocumentedObjects:
  Enabled: true
```

**Example: Different rules for different directories**

```yaml
# Strict documentation for public API
Documentation/UndocumentedMethodArguments:
  Enabled: true
  Exclude:
    - 'lib/internal/**/*'
    - 'spec/**/*'

# But enforce @api tags everywhere
Tags/ApiTags:
  Enabled: true
  Exclude:
    - 'spec/**/*'  # Only exclude specs
```

**Example: Override YARD options per validator**

```yaml
AllValidators:
  # Default: only parse public methods
  YardOptions: []

# Check all methods (including private) for tag order
Tags/Order:
  YardOptions:
    - --private
    - --protected

# But only require documentation for public methods
Documentation/UndocumentedObjects:
  YardOptions: []  # Only public methods
```

This allows you to enforce correct tag formatting on all methods while only requiring documentation on public methods.

**How it works:**

1. **Global exclusions** (defined in `AllValidators/Exclude`) apply to ALL validators
2. **Per-validator exclusions** (defined in each validator's `Exclude`) apply ONLY to that validator
3. Both types of exclusions work together - a file must pass both filters to be checked

Supported glob patterns:
- `**/*` - Recursive match (all files in subdirectories)
- `*.rb` - Simple wildcard
- `lib/foo/*.rb` - Directory with wildcard
- `**/test_*.rb` - Recursive with prefix match

### Available Validators

| Validator | Description | Default | Configuration Options |
|-----------|-------------|---------|----------------------|
| **Documentation Validators** |
| `Documentation/UndocumentedObjects` | Checks for classes, modules, and methods without documentation | Enabled (warning) | `Enabled`, `Severity`, `Exclude`, `AllowEmptyInitialize` |
| `Documentation/UndocumentedMethodArguments` | Checks for method parameters without `@param` tags | Enabled (warning) | `Enabled`, `Severity`, `Exclude` |
| `Documentation/UndocumentedBooleanMethods` | Checks that question mark methods document their boolean return | Enabled (warning) | `Enabled`, `Severity`, `Exclude` |
| **Tags Validators** |
| `Tags/Order` | Enforces consistent ordering of YARD tags | Enabled (convention) | `Enabled`, `Severity`, `Exclude`, `EnforcedOrder` |
| `Tags/InvalidTypes` | Validates type definitions in `@param`, `@return`, `@option` tags | Enabled (warning) | `Enabled`, `Severity`, `Exclude`, `ValidatedTags`, `ExtraTypes` |
| `Tags/ApiTags` | Enforces `@api` tags on public objects | Disabled (opt-in) | `Enabled`, `Severity`, `Exclude`, `AllowedApis` |
| `Tags/OptionTags` | Requires `@option` tags for methods with options parameters | Enabled (warning) | `Enabled`, `Severity`, `Exclude` |
| **Warnings Validators** |
| `Warnings/UnknownTag` | Detects unknown YARD tags | Enabled (error) | `Enabled`, `Severity`, `Exclude` |
| `Warnings/UnknownDirective` | Detects unknown YARD directives | Enabled (error) | `Enabled`, `Severity`, `Exclude` |
| `Warnings/InvalidTagFormat` | Detects malformed tag syntax | Enabled (error) | `Enabled`, `Severity`, `Exclude` |
| `Warnings/InvalidDirectiveFormat` | Detects malformed directive syntax | Enabled (error) | `Enabled`, `Severity`, `Exclude` |
| `Warnings/DuplicatedParameterName` | Detects duplicate `@param` tags | Enabled (error) | `Enabled`, `Severity`, `Exclude` |
| `Warnings/UnknownParameterName` | Detects `@param` tags for non-existent parameters | Enabled (error) | `Enabled`, `Severity`, `Exclude` |
| **Semantic Validators** |
| `Semantic/AbstractMethods` | Ensures `@abstract` methods don't have real implementations | Enabled (warning) | `Enabled`, `Severity`, `Exclude` |

### Global Configuration

| Option | Description | Default | Type |
|--------|-------------|---------|------|
| `AllValidators/YardOptions` | YARD command-line options applied to all validators (e.g., `--private`, `--protected`). Can be overridden per-validator. | `[]` | Array of strings |
| `AllValidators/Exclude` | File patterns to exclude from all validators. Per-validator exclusions are additive. | `['\.git', 'vendor/**/*', 'node_modules/**/*']` | Array of glob patterns |
| `AllValidators/FailOnSeverity` | Exit with error code for this severity level and above | `warning` | `error`, `warning`, `convention`, or `never` |
| `<Validator>/YardOptions` | Override YARD options for a specific validator | Inherits from `AllValidators/YardOptions` | Array of strings |
| `<Validator>/Exclude` | Additional file patterns to exclude for this validator only | `[]` | Array of glob patterns |

## Severity Levels

| Severity | Description | Examples |
|----------|-------------|----------|
| **error** | Critical issues that prevent proper documentation parsing | Unknown tags, invalid formats, malformed syntax, duplicate parameters |
| **warning** | Missing or incorrect documentation | Undocumented methods, missing `@param` tags, invalid type definitions, semantic issues |
| **convention** | Style and consistency issues | Tag ordering, formatting preferences |

## Integration with CI

### GitHub Actions

```yaml
- name: Run YARD Lint
  run: bundle exec yard-lint lib/
```

## CLI Options

YARD-Lint supports the following command-line options:

```bash
yard-lint [options] PATH

Options:
  -c, --config FILE       Path to config file (default: .yard-lint.yml)
  -f, --format FORMAT     Output format (text, json)
  -q, --quiet             Quiet mode (only show summary)
      --stats             Show statistics summary
      --[no-]progress     Show progress indicator (default: auto-detect TTY)
  -v, --version           Show version
  -h, --help              Show this help
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

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

![yard-lint logo](https://raw.githubusercontent.com/mensfeld/yard-lint/master/misc/logo.png)

[![Build Status](https://github.com/mensfeld/yard-lint/actions/workflows/ci.yml/badge.svg)](https://github.com/mensfeld/yard-lint/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/yard-lint.svg)](http://badge.fury.io/rb/yard-lint)

# YARD-Lint

A comprehensive linter for YARD documentation that helps you maintain clean, consistent, and complete documentation in your Ruby and Ruby on Rails projects.

## Why Documentation Quality Matters More Than Ever

Accurate documentation isn't just for human developers anymore. [Research shows](https://arxiv.org/html/2404.03114) that incorrect documentation reduces AI assistant success rates up to 50% (from 44.7% to 22.1%).

**The problem:** Documentation drifts as code changes-parameters get renamed, return types change, but docs stay stale. This doesn't just confuse developers; it trains AI coding assistants to generate confidently wrong code.

**The solution:** YARD-Lint automatically validates your YARD documentation stays synchronized with your code, ensuring both human developers and AI tools have accurate context.

## Features

YARD-Lint validates your YARD documentation for:

- **Undocumented code**: Classes, modules, methods, and constants without documentation
- **Missing parameter documentation**: Methods with undocumented parameters
- **Invalid tag types**: Type definitions that aren't valid Ruby classes or allowed defaults
- **Invalid type syntax**: Malformed YARD type syntax (unclosed brackets, empty generics, etc.)
- **Non-ASCII type characters**: Detects Unicode characters in type specifications (e.g., `…`, `→`, `—`) that are invalid Ruby identifiers
- **Invalid tag ordering**: Tags that don't follow your specified order
- **Meaningless tags**: `@param` or `@option` tags on classes, modules, or constants (only valid on methods)
- **Collection type syntax**: Enforces `Hash{K => V}` over `Hash<K, V>` (YARD standard)
- **Type annotation position**: Validates whether types appear before or after parameter names (configurable)
- **Boolean method documentation**: Question mark methods missing return type documentation
- **API tag validation**: Enforce @api tags on public objects and validate API values
- **Abstract method validation**: Ensure @abstract methods don't have real implementations
- **Option hash documentation**: Validate that methods with options parameters have @option tags
- **Example code syntax validation**: Validates Ruby syntax in `@example` tags to catch broken code examples
- **Redundant parameter descriptions**: Detects meaningless parameter descriptions that add no value (e.g., `@param user [User] The user`)
- **Empty comment lines**: Detects unnecessary empty `#` lines at the start or end of documentation blocks
- **YARD warnings**: Unknown tags, invalid directives, duplicated parameter names, and more
- **Smart suggestions**: Provides "did you mean" suggestions for typos in parameter names using Ruby's `did_you_mean` gem with Levenshtein distance fallback

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

### Quick Start

Generate a default configuration file:

```bash
yard-lint --init
```

This creates `.yard-lint.yml` with sensible defaults in your current directory.

For new projects with high documentation standards, use strict mode:

```bash
yard-lint --init --strict
```

This creates a strict configuration with:
- All validators set to `error` severity (no warnings or conventions)
- Minimum documentation coverage set to 100%
- Perfect for bootstrapping new repositories with high quality standards

### Command Line

Basic usage:

```bash
yard-lint lib/
```

With options:

```bash
# Use a specific config file
yard-lint lib/ --config config/yard-lint.yml

# Output as JSON
yard-lint lib/ --format json > report.json

# Generate config file (use --force to overwrite existing)
yard-lint --init
yard-lint --init --force

# Generate strict config (all errors, 100% coverage)
yard-lint --init --strict
```

### Diff Mode (Incremental Linting)

Lint only files that changed - perfect for large projects, CI/CD, and pre-commit hooks:

```bash
# Lint only files changed since main branch (auto-detects main/master)
yard-lint lib/ --diff

# Lint only files changed since specific branch/commit
yard-lint lib/ --diff develop
yard-lint lib/ --diff HEAD~3

# Lint only staged files (perfect for pre-commit hooks)
yard-lint lib/ --staged

# Lint only uncommitted files
yard-lint lib/ --changed
```

**Use Cases:**

**Pre-commit Hook:**
```bash
#!/bin/bash
# .git/hooks/pre-commit
bundle exec yard-lint lib/ --staged --fail-on-severity error
```

**GitHub Actions CI/CD:**
```yaml
name: YARD Lint
on: [pull_request]
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Need full history for --diff
      - name: Run YARD-Lint on changed files
        run: bundle exec yard-lint lib/ --diff origin/${{ github.base_ref }}
```

**Legacy Codebase Incremental Adoption:**
```bash
# Only enforce rules on NEW code
yard-lint lib/ --diff main
```

### Documentation Coverage Statistics

Monitor and enforce minimum documentation coverage thresholds:

```bash
# Show coverage statistics with --stats flag
yard-lint lib/ --stats

# Output:
# Documentation Coverage: 85.5%
#   Total objects:      120
#   Documented:         102
#   Undocumented:       18

# Enforce minimum coverage threshold (fails if below)
yard-lint lib/ --min-coverage 80

# Use with diff mode to check coverage only for changed files
yard-lint lib/ --diff main --min-coverage 90

# Quiet mode shows only summary with coverage
yard-lint lib/ --quiet --min-coverage 80
```

**Configuration File:**
```yaml
# .yard-lint.yml
AllValidators:
  # Fail if documentation coverage is below this percentage
  MinCoverage: 80.0
```

**CI/CD Pipeline Example:**
```yaml
name: Documentation Quality
on: [pull_request]
jobs:
  coverage:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Check documentation coverage for new code
        run: |
          bundle exec yard-lint \
            lib/ \
            --diff origin/${{ github.base_ref }} \
            --min-coverage 90 \
            --quiet
```

**Key Features:**
- Calculates percentage of documented classes, modules, and methods
- CLI `--min-coverage` flag overrides config file setting
- Exit code 1 if coverage is below threshold
- Works with diff mode to enforce coverage only on changed files
- Performance optimized with auto-cleanup temp directories for large codebases

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

  # Diff mode settings
  DiffMode:
    # Default base ref for --diff (auto-detects main/master if not specified)
    DefaultBaseRef: ~
    # Include untracked files in diff mode (not yet implemented)
    IncludeUntracked: false

# Individual validator configuration
Documentation/UndocumentedObjects:
  Description: 'Checks for classes, modules, and methods without documentation.'
  Enabled: true
  Severity: warning
  # List of methods to exclude from validation
  # Supports three patterns:
  #   - Exact names: 'method_name' (excludes all methods with this name)
  #   - Arity notation: 'method_name/N' (excludes only if method has N parameters)
  #   - Regex patterns: '/pattern/' (excludes methods matching the regex)
  ExcludedMethods:
    - 'initialize/0'  # Exclude only parameter-less initialize (default)
    - '/^_/'          # Exclude private methods (by convention)

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

Tags/TypeSyntax:
  Description: 'Validates YARD type syntax using YARD parser.'
  Enabled: true
  Severity: warning
  ValidatedTags:
    - param
    - option
    - return
    - yieldreturn

Tags/MeaninglessTag:
  Description: 'Detects @param/@option tags on classes, modules, or constants.'
  Enabled: true
  Severity: warning
  CheckedTags:
    - param
    - option
  InvalidObjectTypes:
    - class
    - module
    - constant

Tags/CollectionType:
  Description: 'Validates Hash collection syntax (enforces Hash{K => V} over Hash<K, V>).'
  Enabled: true
  Severity: convention
  ValidatedTags:
    - param
    - option
    - return
    - yieldreturn

Tags/TagTypePosition:
  Description: 'Validates type annotation position in tags.'
  Enabled: true
  Severity: convention
  CheckedTags:
    - param
    - option
  # EnforcedStyle: 'type_after_name' (YARD standard: @param name [Type])
  #                or 'type_first' (@param [Type] name)
  EnforcedStyle: type_after_name

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
yard-lint lib/ --config path/to/config.yml
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
| `Documentation/UndocumentedObjects` | Checks for classes, modules, and methods without documentation | Enabled (warning) | `Enabled`, `Severity`, `Exclude`, `ExcludedMethods` |
| `Documentation/UndocumentedMethodArguments` | Checks for method parameters without `@param` tags | Enabled (warning) | `Enabled`, `Severity`, `Exclude` |
| `Documentation/UndocumentedBooleanMethods` | Checks that question mark methods document their boolean return | Enabled (warning) | `Enabled`, `Severity`, `Exclude` |
| `Documentation/UndocumentedOptions` | Detects methods with options hash/kwargs parameters but no `@option` tags | Enabled (warning) | `Enabled`, `Severity`, `Exclude` |
| `Documentation/MarkdownSyntax` | Detects common markdown syntax errors in documentation (unclosed backticks, invalid list markers, etc.) | Enabled (warning) | `Enabled`, `Severity`, `Exclude` |
| `Documentation/EmptyCommentLine` | Detects empty `#` lines at the start or end of documentation blocks | Enabled (convention) | `Enabled`, `Severity`, `Exclude`, `EnabledPatterns` |
| **Tags Validators** |
| `Tags/Order` | Enforces consistent ordering of YARD tags | Enabled (convention) | `Enabled`, `Severity`, `Exclude`, `EnforcedOrder` |
| `Tags/InvalidTypes` | Validates type definitions in `@param`, `@return`, `@option` tags | Enabled (warning) | `Enabled`, `Severity`, `Exclude`, `ValidatedTags`, `ExtraTypes` |
| `Tags/TypeSyntax` | Validates YARD type syntax (detects unclosed brackets, empty generics, etc.) | Enabled (warning) | `Enabled`, `Severity`, `Exclude`, `ValidatedTags` |
| `Tags/NonAsciiType` | Detects non-ASCII characters in type specifications (e.g., `…`, `→`, `—`) | Enabled (warning) | `Enabled`, `Severity`, `Exclude`, `ValidatedTags` |
| `Tags/MeaninglessTag` | Detects `@param`/`@option` tags on classes, modules, or constants (only valid on methods) | Enabled (warning) | `Enabled`, `Severity`, `Exclude`, `CheckedTags`, `InvalidObjectTypes` |
| `Tags/CollectionType` | Enforces `Hash{K => V}` over `Hash<K, V>` (YARD standard collection syntax) | Enabled (convention) | `Enabled`, `Severity`, `Exclude`, `ValidatedTags` |
| `Tags/TagTypePosition` | Validates type annotation position (`@param name [Type]` vs `@param [Type] name`) | Enabled (convention) | `Enabled`, `Severity`, `Exclude`, `CheckedTags`, `EnforcedStyle` |
| `Tags/ApiTags` | Enforces `@api` tags on public objects | Disabled (opt-in) | `Enabled`, `Severity`, `Exclude`, `AllowedApis` |
| `Tags/OptionTags` | Requires `@option` tags for methods with options parameters | Enabled (warning) | `Enabled`, `Severity`, `Exclude` |
| `Tags/ExampleSyntax` | Validates Ruby syntax in `@example` tags to catch broken code examples | Enabled (warning) | `Enabled`, `Severity`, `Exclude` |
| `Tags/RedundantParamDescription` | Detects meaningless parameter descriptions that add no value beyond the parameter name | Enabled (convention) | `Enabled`, `Severity`, `Exclude`, `CheckedTags`, `Articles`, `MaxRedundantWords`, `MinMeaningfulLength`, `GenericTerms`, `EnabledPatterns` |
| **Warnings Validators** |
| `Warnings/UnknownTag` | Detects unknown YARD tags with "did you mean" suggestions | Enabled (error) | `Enabled`, `Severity`, `Exclude` |
| `Warnings/UnknownDirective` | Detects unknown YARD directives | Enabled (error) | `Enabled`, `Severity`, `Exclude` |
| `Warnings/InvalidTagFormat` | Detects malformed tag syntax | Enabled (error) | `Enabled`, `Severity`, `Exclude` |
| `Warnings/InvalidDirectiveFormat` | Detects malformed directive syntax | Enabled (error) | `Enabled`, `Severity`, `Exclude` |
| `Warnings/DuplicatedParameterName` | Detects duplicate `@param` tags | Enabled (error) | `Enabled`, `Severity`, `Exclude` |
| `Warnings/UnknownParameterName` | Detects `@param` tags for non-existent parameters with "did you mean" suggestions | Enabled (error) | `Enabled`, `Severity`, `Exclude` |
| **Semantic Validators** |
| `Semantic/AbstractMethods` | Ensures `@abstract` methods don't have real implementations | Enabled (warning) | `Enabled`, `Severity`, `Exclude` |

### Detailed Validator Documentation

For detailed documentation on each validator including configuration examples, pattern types, and troubleshooting guides, see the validator module documentation:

- Each validator module file in `lib/yard/lint/validators/` contains comprehensive YARD documentation
- You can browse the source files directly, or generate YARD documentation to view in HTML format:

```bash
yard doc lib/yard/lint/validators/**/*.rb
yard server
```

Then open http://localhost:8808 in your browser to browse the full validator documentation with examples.

### Smart Suggestions with "Did You Mean"

YARD-Lint provides intelligent suggestions for common typos in both tag names and parameter names.

#### Unknown Tag Suggestions

The `Warnings/UnknownTag` validator suggests correct YARD tags for typos:

**Example:**

```ruby
# @params value [String] should be @param
# @returns [String] should be @return
# @raises [Error] should be @raise
def process(value)
  # ...
end
```

**Output:**

```
lib/processor.rb:10: [error] Unknown tag @params (did you mean '@param'?)
lib/processor.rb:11: [error] Unknown tag @returns (did you mean '@return'?)
lib/processor.rb:12: [error] Unknown tag @raises (did you mean '@raise'?)
```

#### Unknown Parameter Suggestions

The `Warnings/UnknownParameterName` validator suggests correct parameter names:

**Example:**

```ruby
# @param usr_name [String] the username
# @param usr_email [String] the email
def create_user(user_name, user_email)
  # ...
end
```

**Output:**

```
lib/user.rb:123: [error] @param tag has unknown parameter name: usr_name (did you mean 'user_name'?)
lib/user.rb:124: [error] @param tag has unknown parameter name: usr_email (did you mean 'user_email'?)
```

**How it works:**
- Uses Ruby's `did_you_mean` gem for intelligent suggestions
- Falls back to Levenshtein distance algorithm when needed
- For parameters: Parses method signatures directly from source files for accurate parameter detection
- Supports all parameter types: regular, keyword, splat, block, and default values
- For tags: Checks against all standard YARD tags and directives

### Quick Configuration Examples

```yaml
# Exclude specific methods from documentation requirements
Documentation/UndocumentedObjects:
  ExcludedMethods:
    - 'initialize/0'       # Parameter-less constructors
    - '/^_/'               # Private methods (by convention)
    - 'to_s'               # String conversion

# Enable @api tag validation (disabled by default)
Tags/ApiTags:
  Enabled: true
  AllowedApis:
    - public
    - private

# Disable a validator
Tags/RedundantParamDescription:
  Enabled: false
```

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
      --min-coverage N    Minimum documentation coverage required (0-100)
      --[no-]progress     Show progress indicator (default: auto-detect TTY)
      --diff [REF]        Lint only files changed since REF
      --staged            Lint only staged files
      --changed           Lint only uncommitted files
      --init              Generate .yard-lint.yml config file
      --strict            Generate strict config (use with --init)
      --force             Force overwrite when using --init
  -v, --version           Show version
  -h, --help              Show this help
```

All configuration (tag order, exclude patterns, severity levels, validator settings) should be defined in `.yard-lint.yml`.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

![yard-lint logo](https://raw.githubusercontent.com/mensfeld/yard-lint/master/misc/logo.png)

[![Build Status](https://github.com/mensfeld/yard-lint/actions/workflows/ci.yml/badge.svg)](https://github.com/mensfeld/yard-lint/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/yard-lint.svg)](http://badge.fury.io/rb/yard-lint)

# YARD-Lint

A comprehensive linter for YARD documentation that helps you maintain clean, consistent, and complete documentation in your Ruby and Ruby on Rails projects.

## Why Documentation Quality Matters More Than Ever

Accurate documentation isn't just for human developers anymore. [Research shows](https://arxiv.org/html/2404.03114) that incorrect documentation reduces AI assistant success rates up to 50% (from 44.7% to 22.1%).

**The problem:** Documentation drifts as code changes-parameters get renamed, return types change, but docs stay stale. This doesn't just confuse developers; it trains AI coding assistants to generate confidently wrong code.

**The solution:** YARD-Lint automatically validates your YARD documentation stays synchronized with your code, ensuring both human developers and AI tools have accurate context.

## Features Overview

YARD-Lint validates your YARD documentation for:

- **Documentation Completeness** - Undocumented classes, modules, methods, parameters, and boolean return values
- **Type Accuracy** - Invalid type definitions, malformed type syntax, non-ASCII characters in types
- **Tag Validation** - Incorrect tag ordering, meaningless tags, invalid tag positions, unknown tags with suggestions
- **Code Examples** - Syntax validation in `@example` tags, optional style validation with RuboCop/StandardRB
- **Semantic Correctness** - Abstract methods with implementations, redundant descriptions
- **Style & Formatting** - Empty comment lines, blank lines before definitions, informal notation patterns
- **Smart Suggestions** - "Did you mean" suggestions for typos in parameter names and tags
- **Configuration Safety** - Validates `.yard-lint.yml` for typos and invalid settings before processing

**See the complete list:** [All 28 Features](https://github.com/mensfeld/yard-lint/wiki/Features) | [30+ Validators](https://github.com/mensfeld/yard-lint/wiki/Validators)

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

**See also:** [Installation Guide](https://github.com/mensfeld/yard-lint/wiki/Installation) - Platform notes, troubleshooting, upgrading

## Quick Start

### Generate Configuration

```bash
# Create .yard-lint.yml with sensible defaults
yard-lint --init

# For new projects with high standards, use strict mode
yard-lint --init --strict
```

### Run on Your Codebase

```bash
# Lint all files in lib/
yard-lint lib/
```

### Update Configuration After Upgrading

```bash
# Add new validators, remove obsolete ones
yard-lint --update
```

**Learn more:** [Configuration Guide](https://github.com/mensfeld/yard-lint/wiki/Configuration)

## Common Workflows

### Lint Only Changed Files (Diff Mode)

Perfect for CI/CD, pre-commit hooks, and legacy codebases:

```bash
# Lint files changed since main branch
yard-lint lib/ --diff

# Lint only staged files (pre-commit hook)
yard-lint lib/ --staged

# Lint uncommitted changes
yard-lint lib/ --changed
```

**Learn more:** [Diff Mode Guide](https://github.com/mensfeld/yard-lint/wiki/Diff-Mode)

### Adopt on Existing Projects (Incremental Adoption)

For projects with many existing violations, generate a baseline that excludes current issues:

```bash
# Generate .yard-lint-todo.yml with exclusions for all current violations
yard-lint --auto-gen-config

# Now yard-lint shows no offenses
yard-lint lib/

# Fix violations incrementally by removing exclusions from .yard-lint-todo.yml
```

**Learn more:** [Incremental Adoption Guide](https://github.com/mensfeld/yard-lint/wiki/Incremental-Adoption)

### Check Documentation Coverage

```bash
# Show coverage statistics
yard-lint lib/ --stats

# Enforce minimum coverage threshold
yard-lint lib/ --min-coverage 80

# Combine with diff mode for new code only
yard-lint lib/ --diff main --min-coverage 90
```

### Run Specific Validators

```bash
# Run only one validator
yard-lint lib/ --only Tags/TypeSyntax

# Run multiple validators
yard-lint lib/ --only Tags/Order,Documentation/UndocumentedObjects
```

**Learn more:** [Advanced Usage Guide](https://github.com/mensfeld/yard-lint/wiki/Advanced-Usage)

## Configuration Basics

Create a `.yard-lint.yml` file in your project root:

```yaml
# Global settings for all validators
AllValidators:
  # YARD command-line options
  YardOptions:
    - --private
    - --protected

  # Global file exclusions
  Exclude:
    - 'vendor/**/*'
    - 'spec/**/*'

  # Exit code behavior (error, warning, convention, never)
  FailOnSeverity: warning

  # Minimum documentation coverage percentage
  MinCoverage: 80.0

# Individual validator configuration
Documentation/UndocumentedObjects:
  Description: 'Checks for classes, modules, and methods without documentation.'
  Enabled: true
  Severity: warning
  ExcludedMethods:
    - 'initialize/0'
    - '/^_/'

Documentation/UndocumentedMethodArguments:
  Enabled: true
  Severity: warning

Tags/Order:
  Enabled: true
  Severity: convention
  EnforcedOrder:
    - param
    - option
    - return
    - raise
    - example

Tags/InvalidTypes:
  Enabled: true
  Severity: warning
  ExtraTypes:
    - CustomType
    - MyNamespace::CustomType
```

**Key features:**
- Per-validator control (enable/disable, severity, exclusions)
- Configuration inheritance with `inherit_from` and `inherit_gem`
- Automatic configuration validation with helpful error messages
- Per-validator YARD options and file exclusions

**Learn more:** [Complete Configuration Guide](https://github.com/mensfeld/yard-lint/wiki/Configuration)

## CI Integration

### GitHub Actions

```yaml
name: YARD Lint
on: [pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Needed for --diff

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true

      - name: Run YARD-Lint on changed files
        run: bundle exec yard-lint lib/ --diff origin/${{ github.base_ref }}
```

### Pre-Commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit
bundle exec yard-lint lib/ --staged --fail-on-severity error
```

### GitLab CI

```yaml
yard-lint:
  stage: test
  script:
    - git fetch origin $CI_MERGE_REQUEST_TARGET_BRANCH_NAME
    - bundle exec yard-lint lib/ --diff origin/$CI_MERGE_REQUEST_TARGET_BRANCH_NAME
  only:
    - merge_requests
```

**Learn more:** [CI/CD Integration Guide](https://github.com/mensfeld/yard-lint/wiki/CI-CD-Integration) - GitHub Actions, GitLab, CircleCI, Jenkins, hooks, badges

## CLI Options

```bash
yard-lint [options] PATH

Configuration:
  -c, --config FILE       Path to config file (default: .yard-lint.yml)

Output:
  -f, --format FORMAT     Output format (text, json)
  -q, --quiet             Quiet mode (only show summary)
      --stats             Show documentation coverage statistics
      --[no-]progress     Show progress indicator (default: auto-detect TTY)

Coverage:
      --min-coverage N    Minimum documentation coverage required (0-100)

Diff Mode:
      --diff [REF]        Lint only files changed since REF
      --staged            Lint only staged files
      --changed           Lint only uncommitted files

Validators:
      --only VALIDATORS   Run only specified validators (comma-separated)

Configuration Generation:
      --init              Generate .yard-lint.yml config file
      --update            Update .yard-lint.yml with new validators
      --strict            Generate strict config (use with --init or --update)
      --force             Force overwrite when using --init
      --auto-gen-config   Generate .yard-lint-todo.yml to silence existing violations
      --regenerate-todo   Regenerate .yard-lint-todo.yml (overwrites existing)
      --exclude-limit N   Min files before grouping into pattern (default: 15)

Information:
  -v, --version           Show version
  -h, --help              Show this help
```

**Learn more:** [Advanced Usage](https://github.com/mensfeld/yard-lint/wiki/Advanced-Usage) - CLI reference, JSON output, coverage

## Documentation

### Quick Links

- **[Wiki Home](https://github.com/mensfeld/yard-lint/wiki)** - Full documentation
- **[Installation](https://github.com/mensfeld/yard-lint/wiki/Installation)** - Installation guide
- **[Configuration](https://github.com/mensfeld/yard-lint/wiki/Configuration)** - Complete configuration reference
- **[Validators](https://github.com/mensfeld/yard-lint/wiki/Validators)** - All 30+ validators documented
- **[Features](https://github.com/mensfeld/yard-lint/wiki/Features)** - All 28 features explained

### Workflows

- **[Incremental Adoption](https://github.com/mensfeld/yard-lint/wiki/Incremental-Adoption)** - Adopt on existing projects
- **[Diff Mode](https://github.com/mensfeld/yard-lint/wiki/Diff-Mode)** - Lint only changed files
- **[Advanced Usage](https://github.com/mensfeld/yard-lint/wiki/Advanced-Usage)** - CLI options, coverage, JSON output

### Integration

- **[CI/CD Integration](https://github.com/mensfeld/yard-lint/wiki/CI-CD-Integration)** - GitHub Actions, GitLab CI, hooks
- **[Troubleshooting](https://github.com/mensfeld/yard-lint/wiki/Troubleshooting)** - Common issues and solutions

## Getting Help

- **Questions or issues?** Open an issue on [GitHub Issues](https://github.com/mensfeld/yard-lint/issues)
- **Need configuration help?** See [Configuration Guide](https://github.com/mensfeld/yard-lint/wiki/Configuration)
- **Common problems?** Check [Troubleshooting](https://github.com/mensfeld/yard-lint/wiki/Troubleshooting)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

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

- **Documentation Completeness** - Undocumented classes, modules, methods, parameters (matched to `@param` tags by name, so a misnamed `@param` is caught), boolean return values, and missing `@return` tags; orphaned doc comments with YARD tags that YARD silently drops
- **Type Accuracy** - Invalid type definitions, malformed type syntax, non-ASCII characters in types, tuple types, literal types (symbols, strings, numbers), and misspelled class names (opt-in via `StrictConstantNames`)
- **Tag Validation** - Incorrect tag ordering, meaningless tags, invalid tag positions, unknown tags with suggestions, forbidden tag patterns, undocumented `yield` calls (opt-in)
- **Parse Errors** - Files YARD cannot parse (syntax errors) are reported instead of silently skipped, so a run never passes over code that does not parse
- **Code Examples** - Syntax validation in `@example` tags (with an opt-in skip for irb/pry/shell console transcripts), optional style validation with RuboCop/StandardRB
- **Semantic Correctness** - Abstract methods with implementations, redundant descriptions
- **Style & Formatting** - Empty comment lines, blank lines before definitions, informal notation patterns, tag group separators, and configurable documentation line length and line fill — flagging comment lines that are too long or prose that wraps before using the available width (both opt-in)
- **Smart Suggestions** - "Did you mean" suggestions for typos in parameter names, tags, and configuration settings
- **Configuration Safety** - Validates `.yard-lint.yml` for typos and invalid settings before processing
- **Performance** - In-process YARD execution with shared registry (~10x faster than shell-based execution)
- **Incremental Adoption** - `--auto-gen-config` generates a baseline todo file to adopt on legacy codebases without fixing everything first

**See the complete list:** [All Features](https://github.com/mensfeld/yard-lint/wiki/Features) | [37 Validators](https://github.com/mensfeld/yard-lint/wiki/Validators)

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

### Lint from stdin (LSP / Editor Integration)

Pass source bytes directly without reading from disk. The `path` argument is still required - it governs config resolution, exclusion matching, and offense location reporting.

**CLI:**

```bash
# Lint source piped through stdin - path is used for config/reporting only
cat lib/foo.rb | yard-lint --stdin lib/foo.rb
```

**Ruby API:**

```ruby
# Lint an in-memory buffer - file does not need to exist on disk
result = Yard::Lint.run(
  path: 'lib/foo.rb',            # used for config, exclusions, and offense locations
  source: editor_buffer_content, # actual source bytes to lint
  progress: false
)
```

This is how [solargraph-yard-lint](https://github.com/lekemula/solargraph-yard-lint) surfaces yard-lint offenses on unsaved editor buffers - the file path provides context while the live buffer content is linted directly, matching the behaviour of RuboCop's `--stdin` flag.

### Quickfix Output (Vim / Emacs)

Use `--format quickfix` to get one offense per line in the standard `file:line: S: Validator: message` format that editors parse natively for their quickfix/error lists:

```bash
yard-lint --format quickfix lib/
```

Example output:

```
lib/foo.rb:42: E: Documentation/UndocumentedObjects: Class Foo is not documented
lib/foo.rb:57: W: Tags/InvalidTypes: has invalid type(s): @return: `Sting`
lib/bar.rb:12: C: Tags/Order: Tags are not in the correct order
```

**Vim** — set `makeprg` and use `:make` to populate the quickfix list:

```vim
set makeprg=yard-lint\ --format\ quickfix\ --no-progress\ %
set errorformat=%f:%l:\ %t:\ %m
```

Then `:make` lints the current file and `:cnext` / `:cprev` jump between offenses. Note: Vim only recognises `E` and `W` as named types for `:clist E`/`:clist W` filtering — `C` (convention) offenses are stored and navigable but appear without a named type in filtered views.

**Emacs** — set `compile-command`:

```elisp
(setq compile-command "yard-lint --format quickfix --no-progress lib/")
```

Then `M-x compile` and `M-g n` / `M-g p` navigate between offenses.

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
  # Skip classes inheriting from these base classes (exact full-path match)
  AllowedParentClasses:
    - StandardError
    - ActiveRecord::Base

Documentation/UndocumentedMethodArguments:
  Enabled: true
  Severity: warning
  # Match each @param to a parameter by name (default). Catches a misnamed tag,
  # not just a missing one. Set to false for a lenient count-only comparison.
  CheckParameterNames: true
  # Opt-in: skip methods with no documentation at all (left to UndocumentedObjects)
  SkipFullyUndocumented: false
  # Skip @param checks for specific methods (exact name, name/arity, /regex/)
  AllowedMethods:
    - call            # service objects: call(args) is self-documenting
    - perform         # background jobs
    - initialize/1    # only this specific arity of initialize

Tags/Order:
  Enabled: true
  Severity: convention
  EnforcedOrder:
    - param
    - option
    - yield
    - yieldparam
    - yieldreturn
    - return
    - raise
    - see
    - example
    - note
    - todo

Tags/InvalidTypes:
  Enabled: true
  Severity: warning
  # ExtraTypes: declare non-standard type names that should not be flagged.
  # Useful for project aliases, LSP extensions (e.g. Solargraph's `generic`),
  # or any informal type name your team uses in YARD docs.
  ExtraTypes:
    - generic          # Solargraph generic type parameter (lsegal/yard#1683)
    - MyNamespace::CustomType
  # Opt-in: flag CamelCase types that are not loaded constants nor defined in the
  # analyzed codebase (catches typos like `Strng`). Enabled by --init --strict.
  StrictConstantNames: false

# Opt-in: Require @return tags on all methods
Documentation/MissingReturn:
  Enabled: true
  Severity: warning
  ExcludedMethods:
    - 'initialize'

# Opt-in: Lint @example code style with RuboCop/StandardRB
Tags/ExampleStyle:
  Enabled: true
  Severity: convention

# Opt-in: Enforce max line length in documentation comments
Documentation/LineLength:
  Enabled: true
  MaxLength: 100

# Opt-in: Flag documentation prose that wraps before using the available width
Documentation/UnderfilledLines:
  Enabled: true
  MaxLength: 100
```

**Key features:**
- Per-validator control (enable/disable, severity, exclusions)
- Configuration inheritance with `inherit_from` and `inherit_gem`
- Automatic configuration validation with helpful error messages
- Per-validator YARD options and file exclusions

**Learn more:** [Complete Configuration Guide](https://github.com/mensfeld/yard-lint/wiki/Configuration)

## Catching Orphaned Documentation Comments

YARD silently ignores comment blocks that contain YARD tags (`@param`, `@return`, etc.) when they are not immediately followed by a documentable construct (method, class, module, constant, attribute). This happens with local variable assignments, `require` calls, `include`/`extend` statements, bare `private`/`public` keywords, or comments at the end of a file - the documentation is simply lost with no warning.

The `Documentation/OrphanedDocComment` validator (enabled by default) catches this:

```ruby
# Bad - YARD drops this silently; local variable is not documentable
# @param name [String] the name
# @return [void]
local_var = "value"

# Bad - require is not documentable
# @param id [Integer] user id
# @return [User]
require 'some_gem'

# Bad - orphaned at end of file
# @param id [Integer] user id
# @return [User]

# Good - properly attached to a method
# @param name [String] the name
# @return [void]
def greet(name); end

# Good - constant assignments are documentable, not flagged
# @return [Integer] the answer
ANSWER = 42

# Good - DSL calls (ransacker, validates, scope, ...) are turned into method
# objects by YARD's DSL handler when the comment carries a tag like @return,
# so they are documentable and not flagged
# @return [Arel::Nodes::Node]
ransacker :owner_name do
  Arel.sql("...")
end
```

This validator is complementary to `Documentation/BlankLineBeforeDefinition` (which handles the case where blank lines separate a doc comment from a `def` - YARD still attaches it despite the gap).

## Documenting yield (opt-in)

The `Tags/MissingYield` validator (opt-in, disabled by default) detects methods that call `yield` in their body but do not document the block with a `@yield`, `@yieldparam`, or `@yieldreturn` tag. Callers need to know a method yields in order to pass a block.

Enable it in `.yard-lint.yml`:

```yaml
Tags/MissingYield:
  Enabled: true
  Severity: warning
```

```ruby
# Bad - method yields but block is not documented
# @param items [Array] the items to process
def each(items)
  items.each { |item| yield item }
end

# Good - block documented with @yield
# @param items [Array] the items to process
# @yield [item] each item in the collection
def each(items)
  items.each { |item| yield item }
end

# Good - @yieldparam is also accepted
# @param items [Array] the items to process
# @yieldparam item [Object] each item
def each(items)
  items.each { |item| yield item }
end
```

Method calls like `Fiber.yield` and `yielder.yield` (Enumerator::Yielder) are not flagged - only the `yield` keyword triggers the check.

## Encouraging full-width documentation (opt-in)

`Documentation/LineLength` flags comment lines that are too *long*. `Documentation/UnderfilledLines` is its inverse: it flags documentation prose that wraps **too early** - text that uses only a fraction of the available width and spills onto extra lines, wasting vertical space. This pattern is especially common in AI-generated documentation.

Enable it in `.yard-lint.yml`:

```yaml
Documentation/UnderfilledLines:
  Enabled: true
  MaxLength: 120          # target width (match your Documentation/LineLength)
  MinTrailingSpace: 20    # only flag when the widest line wastes >= 20 columns
```

```ruby
# Bad - prose wraps at ~55 columns when 120 are available
# Processes the incoming payload and returns a normalized
# hash that downstream consumers can rely on for routing.
def process(payload); end

# Good - prose fills the available width before wrapping
# Processes the incoming payload and returns a normalized hash that downstream
# consumers can rely on for routing.
def process(payload); end
```

The validator reports one offense per wasteful paragraph and is deliberately conservative - it would rather miss a case than emit a false positive. It only looks at the free-text description body (tags, fenced/indented code, lists, tables, headings, blockquotes and non-ASCII text are left alone), and a paragraph is reported only when re-wrapping its words at `MaxLength` would genuinely use fewer lines.

Unlike `LineLength` (which measures an objective property), "this line should have been longer" is a stylistic judgement. Projects that use **semantic line breaks** (one sentence or clause per line, see [sembr.org](https://sembr.org)) are never flagged - any paragraph whose non-final lines all end at a sentence boundary (`.?!:;`) is treated as intentional. Leave the validator off, or add `,` to `SentenceEndChars`, if that style is used heavily.

## Handling Non-Standard Types

By default `Tags/InvalidTypes` accepts all built-in Ruby classes, constants, and a set of YARD pseudo-types (`nil`, `true`, `false`, `self`, `void`, `Boolean`, `undefined`, `unspecified`, `unknown`). If your project uses additional type names that are not real Ruby classes - project-specific aliases, LSP extensions, or informal conventions - you can declare them via `ExtraTypes` so yard-lint does not report them as `InvalidTagType` offenses.

### Project-Specific Type Aliases

```yaml
Tags/InvalidTypes:
  ExtraTypes:
    - Callable        # informal "anything that responds to #call"
    - Awaitable       # async type alias used across the project
    - Result          # dry-monad-style Result type used in prose docs
```

### LSP / Tool-Specific Extensions

[Solargraph](https://solargraph.org) supports a `generic` type-parameter notation (e.g. `Hash{Class<generic<T>> => Set<generic<T>>}`) that is [proposed for adoption](https://github.com/lsegal/yard/issues/1683) but not yet part of the YARD standard. Until it is, add it to `ExtraTypes` to prevent false positives:

```yaml
Tags/InvalidTypes:
  ExtraTypes:
    - generic
```

### Built-In Pseudo-Types (no configuration needed)

The following YARD pseudo-types are accepted out of the box and do **not** need to be listed in `ExtraTypes`:

| Type | Meaning |
|------|---------|
| `nil` | Explicitly nil |
| `true` / `false` | Boolean literals |
| `Boolean` | YARD boolean pseudo-type (`true` or `false`) |
| `self` | Returns the receiver |
| `void` | No meaningful return value |
| `undefined` | Type is intentionally unspecified (used by Solargraph) |
| `unspecified` | Alias for undefined |
| `unknown` | Type is unknown |

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
bundle exec yard-lint lib/ --staged
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
  -f, --format FORMAT     Output format (text, json, quickfix)
  -q, --quiet             Quiet mode (only show summary)
      --stats             Show documentation coverage statistics
      --[no-]progress     Show progress indicator (default: auto-detect TTY)
      --stdin             Read source from stdin; PATH still required for config/reporting

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

## Offense Structure

Every offense (in text, JSON, and quickfix output) includes a `validator` field with the full config key that produced it, making it easy to find the right `.yard-lint.yml` setting to adjust:

```json
{
  "name": "OrphanedDocComment",
  "validator": "Documentation/OrphanedDocComment",
  "severity": "warning",
  "message": "Documentation comment with @param, @return is orphaned - YARD will ignore it",
  "location": "lib/my_class.rb",
  "location_line": 42
}
```

The text formatter also shows the validator path (e.g., `[Documentation/OrphanedDocComment]`) instead of just the short offense name.

## Documentation

### Quick Links

- **[Wiki Home](https://github.com/mensfeld/yard-lint/wiki)** - Full documentation
- **[Installation](https://github.com/mensfeld/yard-lint/wiki/Installation)** - Installation guide
- **[Configuration](https://github.com/mensfeld/yard-lint/wiki/Configuration)** - Complete configuration reference
- **[Validators](https://github.com/mensfeld/yard-lint/wiki/Validators)** - All 37 validators documented
- **[Features](https://github.com/mensfeld/yard-lint/wiki/Features)** - All features explained

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

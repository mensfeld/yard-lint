# YARD-Lint Changelog

## 1.2.0 (2025-11-11)
- **[Feature]** Add Diff Mode for incremental linting - only analyze files that changed
  - `--diff [REF]` - Lint only files changed since REF (auto-detects main/master if not specified)
  - `--staged` - Lint only staged files (git index)
  - `--changed` - Lint only uncommitted files
  - Enables practical usage in large legacy codebases
  - Perfect for CI/CD pipelines (only check what changed in PR)
  - Ideal for pre-commit hooks (only check staged files)
  - Auto-detects main/master branch with fallback to master
  - Applies global exclusion patterns to git diff results
  - Silently skips deleted files
  - Returns clean result when no files are changed
  - Uses shell-based git commands via Open3 (no new dependencies)
  - Configuration support via `AllValidators.DiffMode` section
  - Mutually exclusive diff flags (--diff, --staged, --changed)

## 1.1.0 (2025-11-11)
- **[Feature]** Add `Tags/ExampleSyntax` validator to validate Ruby syntax in `@example` tags
  - Uses Ruby 3.2's `RubyVM::InstructionSequence.compile()` to parse example code
  - Automatically strips output indicators (`#=>`) before validation
  - Intelligently skips incomplete single-line snippets (e.g., `multiply(3, 4)`)
  - Reports multi-line syntax errors with full context from Ruby's parser
  - Enabled by default with 'warning' severity
  - Helps prevent broken code examples in documentation
- **[Feature]** Add `Tags/RedundantParamDescription` validator to detect meaningless parameter descriptions
  - Detects 7 types of redundant patterns: article+param, possessive, type restatement, param-to-verb, ID pattern, directional date, type+generic
  - Configurable pattern toggles to enable/disable individual pattern types
  - Word count threshold (`MaxRedundantWords`: 6) prevents false positives on longer descriptions
  - Character length threshold (`MinMeaningfulLength`: 15) for additional context
  - Configurable articles list (`Articles`: The, the, A, a, An, an)
  - Configurable generic terms list (`GenericTerms`: object, instance, value, data, item, element)
  - Pattern-specific error messages with actionable suggestions
  - EXACT pattern matching (not prefix) to avoid false positives
  - Enabled by default with 'convention' severity
  - Helps maintain high-quality, meaningful documentation
- **[Feature]** Add `--init` command to generate `.yard-lint.yml` configuration file with sensible defaults
- **[Feature]** Add `--force` flag to overwrite existing config file when using `--init`
- **[Feature]** Add `EnforcedStyle` configuration option to `Tags/CollectionType` validator for bidirectional style enforcement
  - Supports 'long' style: `Hash{K => V}` (default, standard YARD syntax)
  - Supports 'short' style: `{K => V}` (Ruby-like syntax without Hash prefix)
  - Automatically detects violations in either direction and suggests correct style
  - Updated messages to show correct suggestion based on enforced style
- **[Feature]** Add `Documentation/UndocumentedOptions` validator to detect methods with options hash parameters but no @option tags
  - Detects `options = {}`, `opts = {}`, `**kwargs`, and similar patterns
  - Helps catch missing documentation for option hash parameters
  - Configurable via `Documentation/UndocumentedOptions` in config
- **[Feature]** Add `Documentation/MarkdownSyntax` validator to detect common markdown syntax errors in documentation
  - Detects unclosed backticks in inline code
  - Detects unclosed code blocks (```)
  - Detects unclosed bold formatting (**)
  - Detects invalid list markers (• instead of - or *)
  - Configurable via `Documentation/MarkdownSyntax` in config
- [Enhancement] Simplify README by condensing alternative style examples
- [Documentation] Add Quick Start section to README with `--init` command
- [Documentation] Update CLI help to show new `--init` and `--force` options

## 1.0.0 (2025-11-09)
- [Fix] Fix "Argument list too long" error on large codebases by using xargs pattern with temporary file lists
- [Enhancement] Expand default exclusion patterns to include typical Ruby/Rails directories (test/, log/, coverage/, db/migrate/, etc.)
- **[Feature]** Add `Tags/TypeSyntax` validator to detect malformed YARD type syntax using YARD's built-in parser
  - Detects unclosed brackets: `Array<`, `Hash{Symbol =>`
  - Detects empty generics: `Array<>`
  - Detects malformed hash syntax: `Hash{Symbol}`
  - Configurable `ValidatedTags` option (default: param, option, return, yieldreturn)
- **[Feature]** Add `Tags/MeaninglessTag` validator to detect `@param` and `@option` tags on non-method objects
  - Prevents meaningless tags on classes, modules, and constants
  - Configurable `CheckedTags` (default: param, option) and `InvalidObjectTypes` (default: class, module, constant)
- **[Feature]** Add `Tags/CollectionType` validator to enforce YARD's Hash collection syntax
  - Enforces `Hash{K => V}` over `Hash<K, V>` (generic syntax from other languages)
  - Configurable `ValidatedTags` (default: param, option, return, yieldreturn)
  - Provides automatic correction suggestions
- **[Feature]** Add `Tags/TagTypePosition` validator to validate type annotation position in tags
  - Configurable style: `type_after_name` (YARD standard: `@param name [Type]`) or `type_first` (`@param [Type] name`)
  - Only validates `@param` and `@option` tags (excludes `@return` as it has no parameter name)
  - Reads source code directly to avoid false positives from YARD's internal docstring normalization
- [Fix] Fix `Warnings/UnknownParameterName` validator showing only line number instead of full file path by correcting regex pattern
- [Enhancement] Add comprehensive integration tests for `UnknownParameterName` validator
- [Documentation] Add inline documentation explaining cache clearing in bin/yard-lint
- [Documentation] Expand README with troubleshooting section for ExcludedMethods patterns

## 0.2.2 (2025-11-07)
- **[Feature]** Add `ExcludedMethods` configuration option to exclude methods from validation using simple names, regex patterns, or arity notation (default excludes parameter-less `initialize/0` methods).
- [Fix] Fix `UndocumentedObjects` validator incorrectly flagging methods with `@return [Boolean]` tags as undocumented by using `docstring.all.empty?` instead of `docstring.blank?`.
- [Fix] Fix `UndocumentedBooleanMethods` validator incorrectly flagging methods with `@return [Boolean]` (type without description text) by checking for return types instead of description text.
- [Enhancement] Implement per-arguments YARD database isolation using SHA256 hash of arguments to prevent contamination between validators with different file selections.
- [Refactoring] Remove file filtering workaround as database isolation eliminates the need for it.
- [Change] YARD database directories are now created under a base temp directory with unique subdirectories per argument set.

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

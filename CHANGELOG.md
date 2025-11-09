# YARD-Lint Changelog

## Unreleased
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

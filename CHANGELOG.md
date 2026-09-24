## Unreleased
- **[Enhancement]** SARIF output now includes a line-independent `partialFingerprints` per result, so GitHub tracks the same offense across commits instead of churning alerts when lines shift.
- **[Feature]** Added `--format sarif`, which emits SARIF 2.1.0 for GitHub code scanning and other aggregators.
- **[Feature]** Category-level `Severity` is now honored: set `Severity` on a department (e.g. `Documentation`) to apply it to all its validators. A per-validator `Severity` still wins. Backwards compatible - it only affects configs that set a category `Severity`, which was previously ignored.

## 1.12.0 (2026-09-23)
- **[Feature]** Added `--explain VALIDATOR`, which prints a validator's description, default severity, configuration options, and examples in the terminal (sourced from its own YARD docs). Unknown names suggest close matches, like `--only`.
- **[Bugfix]** `Tags/TagSeparator` and `Tags/TagGroupSeparator` no longer report false positives on `module_function` methods, which YARD registers twice with one docstring's layout normalized. A genuinely unseparated `module_function` method is still reported once.
- **[Bugfix]** `Tags/TagSeparator` and `Tags/TagGroupSeparator` now report each docstring once even when YARD generates multiple objects from it (e.g. an `attr_accessor` reader and writer).

## 1.11.0 (2026-08-11)
- **[Maintenance]** Re-release of `1.10.3` as `1.11.0` due to new features being present.

## 1.10.3 (2026-08-05)
- **[Feature]** Added `Tags/TagSeparator` (opt-in, severity `convention`) - a stricter sibling of `Tags/TagGroupSeparator` that requires a blank line between every pair of consecutive tags. Tags under `Exempt` may follow directly, and `RequireAfterDescription` also requires a blank line after the description.
- **[Feature]** `Documentation/UndocumentedObjects` gained an `ExcludedObjects` option that excludes any object - class, module, method, or constant - by fully-qualified name (exact or `/regex/`), including constants that `ExcludedMethods` could never match (#299).
- **[Feature]** `Documentation/BlankLineBeforeDefinition` gained an `IgnoredCommentPatterns` option: comment lines matching a configured string or `/regex/` are not treated as documentation, avoiding false positives on commented-out code, `# FIXME` notes, and section separators. Defaults to empty (#300).
- **[Bugfix]** `Documentation/BlankLineBeforeDefinition` offenses now carry their validator name (previously an empty slot in the output) (#300).
- **[Bugfix]** `Documentation/OrphanedDocComment` no longer flags a tagged doc comment above a class variable assignment (`@@name = ...`), which YARD does document.

## 1.10.2 (2026-07-24)
- **[Bugfix]** `Semantic/AbstractMethods` no longer flags an `@abstract` method whose body is `fail NotImplementedError`; `fail` is now normalized to `raise` before matching `AllowedImplementations`.

## 1.10.1 (2026-07-24)
- **[Bugfix]** `Documentation/BlankLineBeforeDefinition` no longer reports a file-header/license banner or unrelated comment above a documented definition as a detached docstring. Genuinely lost documentation is still reported.

## 1.10.0 (2026-07-24)
- **[Feature]** Added `Documentation/DuplicateNamespaceComment` (enabled by default, severity `warning`) - detects a namespace documented in more than one file, where YARD silently keeps only one docstring and discards the rest. Reports each such namespace with all documented locations and whether the docstrings differ.

## 1.9.0 (2026-07-01)
- **[Breaking]** Dropped support for Ruby 3.2; the minimum is now Ruby 3.3.0 (the `parallel` gem no longer supports 3.2).

## 1.8.0 (2026-06-17)
- **[Feature]** Added `Documentation/UnderfilledLines` (opt-in, severity `convention`) - the inverse of `Documentation/LineLength`: flags documentation prose that wraps too early and wastes width. Deliberately conservative and never flags semantic line breaks. Configurable via `MaxLength`, `MinTrailingSpace`, `MinParagraphLines`, `SentenceEndChars`, and `SkipNonAscii`.
- **[Change]** Centralized source-file reading into `Validators::Base#cached_lines`, which also scrubs invalid bytes so a non-UTF-8 source file no longer crashes a validator.

## 1.7.0 (2026-06-15)
- **[Feature]** `Tags/ExampleSyntax` gained an opt-in `SkipNonRuby` option (default `false`) to skip `@example` blocks that are irb/pry/shell transcripts rather than reporting them as syntax errors.
- **[Feature]** `Tags/InvalidTypes` gained an opt-in `StrictConstantNames` option (default `false`) that flags a CamelCase type which is neither a loaded constant nor resolvable in the codebase (catching typos like `Strng`). Enabled by the strict template; `Boolean` is always accepted.
- **[Feature]** `Tags/InformalNotation` gained an opt-in `SkipIndentedCodeBlocks` option (default `false`) to skip 4-space/tab indented Markdown code blocks.
- **[Feature]** Added `Warnings/SyntaxError` (enabled by default, severity `error`) - a Ruby file YARD cannot parse is now reported as an offense (with file and line) instead of being silently skipped.
- **[Fix]** `Documentation/UndocumentedMethodArguments` now matches each parameter to its `@param` tag by name (catching a misnamed tag) - the new default; set `CheckParameterNames: false` for the old count-only check. An opt-in `SkipFullyUndocumented` skips wholly undocumented methods.
- **[Fix]** `yard-lint --diff PATH` (e.g. `--diff lib/`) no longer fails with an ambiguous-argument git error; a `--diff` value that is a path rather than a ref is now treated as the path.
- **[Fix]** `Documentation/TextSubstitution` no longer flags a forbidden string inside an inline code span (`` `…` ``).
- **[Fix]** `Documentation/OrphanedDocComment` no longer treats `#`-leading lines inside heredocs or string literals as comments (it now uses the Ruby lexer).
- **[Fix]** `Documentation/OrphanedDocComment` no longer flags three more documented DSL constructs: a wrapped def (`memoize def ...`), a receiver DSL call, and a call whose comment carries a `@method`/`@attribute` tag.
- **[Fix]** `Tags/TagTypePosition` no longer scans a blank-line-detached comment, and no longer flags a valid `@option` under `EnforcedStyle: type_first`.
- **[Fix]** `Documentation/MarkdownSyntax` no longer reports the exponent operator (`x ** y`) or a `**opts` splat inside an `@example` as unclosed bold; it now skips fenced code blocks.
- **[Fix]** `--update` and `--auto-gen-config` now honor the `-c CONFIG` path instead of always targeting `./.yard-lint.yml`.
- **[Fix]** Diff modes (`--diff`/`--staged`/`--changed`) now find changed files whose names contain non-ASCII characters (git-quoted paths are now unquoted).
- **[Fix]** `Documentation/OrphanedDocComment` no longer treats a prose comment that merely starts with a magic-comment word (e.g. `# encoding: ...`) as a real magic comment.
- **[Fix]** `--changed` now includes untracked files, not just tracked changes.
- **[Fix]** An unnamed `@example` no longer corrupts `Tags/ExampleSyntax` / `Tags/ExampleStyle` output; the "Example N" fallback now fires on YARD's empty name.
- **[Fix]** Custom tags declared in a project's `.yardopts` (e.g. `--tag`) are no longer reported as `Warnings/UnknownTag`.
- **[Fix]** `Tags/InformalNotation` now suggests `@note` (not `@deprecated`) for a `Warning:` notation.
- **[Fix]** `--auto-gen-config` no longer writes offenses already silenced by a per-validator `Exclude` into the generated baseline.
- **[Fix]** Documentation coverage is no longer reported as 100% when the `yard` stats subprocess fails; failure now yields unknown coverage and fails a `MinCoverage` gate safely.
- **[Fix]** Offenses with `never` severity no longer cause a non-zero exit under `FailOnSeverity: convention`.
- **[Fix]** `--auto-gen-config` now emits a usable exclude pattern (`**/*`) for grouped root-level files, so the generated baseline actually excludes them.
- **[Fix]** `Tags/RedundantParamDescription`'s `ParamToVerb` pattern now fires only when the word after "to" is a low-value verb, so phrases like `path to file` are no longer flagged.
- **[Fix]** `Tags/NonAsciiType` no longer flags non-ASCII characters inside string or quoted-symbol literal types (e.g. `"naïve"`).
- **[Fix]** `Warnings/UnknownParameterName`'s "did you mean" engine now reads parameters from the correct method and parses modern signatures (receiver methods, keyword defaults, defaults containing commas); the dead `yard list` fallback was removed.
- **[Fix]** The "did you mean" Levenshtein fallback no longer offers absurd suggestions for short, very different names (e.g. `@foo` → `@todo`).
- **[Fix]** `AllValidators.DiffMode.DefaultBaseRef` is now honored before falling back to main/master auto-detection.
- **[Fix]** `Semantic/AbstractMethods` now honors its `AllowedImplementations` option, which was previously defined but never read.
- **[Fix]** `Tags/CollectionType` now produces a valid long-syntax suggestion for nested short-style hashes (e.g. `Hash{Symbol => Hash{String => Integer}}`).
- **[Fix]** An unknown `--format` value is now rejected up front instead of after the whole run.
- **[Fix]** The config error for an unrecognizable validator name now links the wiki Validators page instead of a nonexistent `--list-validators` flag.
- **[Fix]** Category-level `Enabled` (e.g. `Documentation: { Enabled: false }`) is now honored instead of silently ignored; a per-validator setting still wins.
- **[Fix]** `Tags/ApiTags` no longer requires an `@api` tag on constants (only classes, modules, and methods).
- **[Fix]** Diff modes now find changed files when run from a repository subdirectory (paths are resolved against the repo root).
- **[Fix]** Diamond-shaped config inheritance no longer raises a false `CircularDependencyError`; true cycles are still detected.
- **[Fix]** `Tags/ExampleSyntax` no longer reports bogus syntax errors for a `# =>` sequence inside a string literal (stripping is now comment-aware).
- **[Fix]** `Tags/CollectionType` no longer flags custom classes whose names merely contain `Hash` or `Array` (e.g. `MyHash<...>`).
- **[Fix]** `Tags/Order` no longer crashes when `EnforcedOrder` is set to null in the config; it falls back to the default order.
- **[Fix]** `Tags/OptionTags` no longer demands `@option` tags for a parameter with an options-like name that is documented as a non-Hash type.
- **[Fix]** `Tags/TagGroupSeparator` no longer treats indented `@`-leading lines inside an `@example` (e.g. `@result = ...`) as tag groups.
- **[Fix]** `Documentation/MarkdownSyntax` no longer reports a spurious unclosed backtick for a backtick inside a fenced code block.
- **[Fix]** The in-process registry now restores YARD's global logger level even when parsing raises.
- **[Fix]** `Documentation/UndocumentedOptions` no longer demands `@option` tags for an options-named parameter documented as a non-Hash type.
- **[Fix]** `--auto-gen-config` no longer destroys comments and formatting in an existing `.yard-lint.yml` when adding the `inherit_from` line (it now edits the file textually).
- **[Fix]** `yard-lint --update` no longer silently drops `inherit_from` / `inherit_gem` directives (which had resurrected baselined offenses).
- **[Fix]** The one-line YARD-warning parsers now extract the line number and message correctly when the file path contains `line ` or ` in file `.
- **[Fix]** `Documentation/UndocumentedMethodArguments` no longer demands `@param` tags for block (`&block`) or splat (`*args`, `**opts`) parameters.
- **[Fix]** `Documentation/EmptyCommentLine` no longer attributes a blank-line-detached file-header comment to a definition.
- **[Fix]** `Documentation/BlankLineBeforeDefinition` no longer treats shebangs, tool directives (Sorbet/RuboCop/Standard), or a bare `#` as documentation.
- **[Fix]** The CLI now prints a clean one-line error (not a Ruby backtrace) for an unknown flag or a missing `-c` config file.
- **[Fix]** `Semantic/AbstractMethods` no longer flags an `@abstract` method whose body is a multi-line `raise NotImplementedError, "message"` (continuations are now merged).
- **[Fix]** `Tags/RedundantParamDescription` no longer treats any word starting with "a"/"an"/"the" as an article; articles now match whole words only.
- **[Fix]** `Tags/ApiTags` now validates only the `@api` value itself, not indented continuation/description lines.
- **[Fix]** `Semantic/AbstractMethods` and `Tags/OptionTags` offenses now include the `validator` field, so formatters no longer print an empty validator path.
- **[Fix]** `Warnings/UnknownTag` now renders a directive suggestion with the `@!` prefix (e.g. `@!parse`) instead of a plain `@`.
- **[Fix]** The shipped config templates (`--init`, `--init --strict`) no longer silently narrow validation versus running with no config; templates are synced with code defaults and a parity test prevents future drift.
- **[Fix]** `Documentation/UndocumentedObjects`'s `ExcludedMethods` no longer silently suppresses offenses for classes, modules, or constants; it now applies only to methods.
- **[Fix]** A missing `inherit_from` target (most importantly the `.yard-lint-todo.yml` baseline) now prints a warning naming the file instead of being silently ignored.
- **[Fix]** Config files using YAML anchors/aliases no longer crash on Psych 4+; malformed YAML now raises the gem's own `InvalidConfigError` with the file and message.
- **[Fix]** Docstring-content offenses (`Documentation/TextSubstitution`, `Tags/InformalNotation`, `Documentation/MarkdownSyntax`) now point at the offending documentation line instead of the definition line.
- **[Fix]** `Tags/MissingYield` no longer flags methods that use `yield:` as a symbol key or keyword-argument label.
- **[Fix]** One documentation problem now produces one offense; offenses shared across YARD-generated methods (e.g. an `attr_accessor` reader and writer) are deduplicated.
- **[Fix]** `@option` tag types and descriptions are now actually validated by `Tags/InvalidTypes`, `Tags/CollectionType`, `Tags/ForbiddenTags`, and `Tags/RedundantParamDescription` (YARD stores the data on a nested pair tag).
- **[Fix]** Tags written inside `@overload` blocks now count as documentation for `Documentation/MissingReturn`, `Documentation/UndocumentedMethodArguments`, and `Tags/OptionTags`, and are detected by `Tags/ForbiddenTags`.
- **[Fix]** `Tags/Order` and `Tags/TagGroupSeparator` now pair each offense with its own payload, so an unparseable location line no longer shifts offenses onto other objects.
- **[Fix]** `Tags/Order` and `Tags/TagGroupSeparator` now check class, module, and constant docstrings (previously skipped due to a swallowed `NameError`).
- **[Fix]** Offenses on top-level methods and constants are no longer silently discarded by the shared location parser.
- **[Fix]** Boolean validator options explicitly set to `false` in `.yard-lint.yml` are no longer ignored in favor of a truthy default.

## 1.6.1 (2026-06-11)
- **[Fix]** `Documentation/OrphanedDocComment` no longer reports false positives for documented DSL-style calls (e.g. `ransacker :foo do … end`, `validates :name`, `scope`) whose preceding comment carries an implicit-docstring tag, nor for the bare `attr :name` form.

## 1.6.0 (2026-06-11)
- **[Feature]** New `--format quickfix` output mode emits one offense per line as `file:line: S: Validator: message`, for Vim/Emacs navigation. Produces no output (and exits 0) when clean.
- **[Feature]** New opt-in validator `Documentation/LineLength` flags documentation comment lines over a configurable `MaxLength` (default 120) (#176).
- **[Feature]** `Yard::Lint.run` accepts an optional `source:` argument for linting in-memory source, and the CLI gains a `--stdin` flag - enabling LSP/editor integrations to lint unsaved buffers (#173).
- **[Feature]** `Documentation/UndocumentedMethodArguments` gained an `AllowedMethods` option (exact name, arity notation, or `/regex/`) to skip `@param` checks for idiomatic methods like `call`.
- **[Feature]** All Documentation validators gained an `AllowedParentClasses` option to skip classes/methods whose enclosing class inherits from a listed base (e.g. `StandardError`, `ActiveRecord::Base`); `Object`/`BasicObject` are never matched.
- **[Feature]** New opt-in validator `Tags/MissingYield` flags methods that call `yield` but do not document the block with `@yield`/`@yieldparam`/`@yieldreturn`.
- **[Feature]** New opt-in validator `Documentation/TextSubstitution` flags forbidden strings and suggests replacements (ships with em-dash/en-dash → hyphen); fully configurable via `Substitutions` (#182).
- **[Feature]** New validator `Documentation/OrphanedDocComment` (enabled by default) detects tagged comment blocks not attached to any documentable construct, which YARD silently drops.
- **[Enhancement]** Each offense now includes a `validator` field with the full config key, and the text formatter displays it, making it easier to find the right `.yard-lint.yml` setting.
- **[Fix]** `Tags/InvalidTypes` no longer reports false positives for YARD's semicolon shorthand in multi-pair fixed-shape Hash types (#171).
- **[Enhancement]** Added a Ruby warning-category opt-in to the test helpers.
- **[Fix]** Restored `warn` in `InProcessRegistry#capture_warnings` without a spurious method-redefinition warning.

## 1.5.2 (2026-06-02)
- **[Fix]** `Tags/InvalidTypes` no longer flags the YARD pseudo-types `undefined`, `unspecified`, and `unknown` (#152).
- **[Fix]** `Tags/InvalidTypes` no longer flags string-literal hash keys (e.g. `Hash{"to" => String}`) (#152).
- **[Fix]** `Tags/InvalidTypes` no longer flags nested `Hash{K => V}` types; genuinely invalid nested types are still caught (#151, #152).
- **[Enhancement]** `Tags/InvalidTypes` offense messages now name the invalid type(s) and the tag they appear in (#151).
- **[Fix]** `Tags/MeaninglessTag` no longer flags `@param` on `Struct.new` / `Data.define` constants (used by Solargraph to type accessors); `@option` is still reported (#152).
- **[Fix]** `--auto-gen-config` no longer crashes (`NoMethodError`) when a YARD warning is emitted without a file path; nil-location offenses are now dropped, and `Warnings/DuplicatedParameterName` now parses YARD's two-line format (#150).
- **[Fix]** `Tags/InvalidTypes` no longer flags allowed defaults (`self`, `nil`, `true`, `false`, `void`) inside generic types (e.g. `Array<self>`).
- **[Fix]** All type validators (`Tags/TypeSyntax`, `Tags/InvalidTypes`, `Tags/CollectionType`, `Tags/NonAsciiType`) now validate types inside `@overload` blocks.
- **[Fix]** `@raise` and `@yieldparam` types are now validated consistently across all type validators.
- **[Fix]** `Tags/ApiTags` no longer flags attribute accessors generated by `attr_*`, `@!attribute`, `Struct.new`, or `Data.define` for missing `@api` tags (#128).

## 1.5.1 (2026-04-09)
- **[Fix]** Excluded non-production files (`.ruby-version`, `Rakefile`, `misc/`, `mise.toml`, lock files, etc.) from RubyGems releases.

## 1.5.0 (2026-04-02)
- **[Fix]** `Documentation/UndocumentedMethodArguments` now skips `@!attribute` accessor methods, matching `attr_accessor` behavior (#115).
- **[Fix]** `Tags/CollectionType` now enforces style for Array types (long/short forms), not just Hash, with matching correction suggestions (#114).
- **[Fix]** `Tags/InvalidTypes` now accepts tuple (fixed-length array) types like `(String, Integer)` (#113).
- **[Fix]** `Tags/TypeSyntax` now accepts symbol, string, and numeric literal types (e.g. `:error`, `"read"`, `-1`, `2.5`) that YARD's parser rejects (#109).
- **[Feature]** Added configuration validation that catches unknown validator names, invalid severities (with "did you mean"), bad boolean values, and invalid global settings, failing fast with clear messages.
- **[Feature]** Added `Tags/ExampleStyle` validator (opt-in) that lints `@example` code with RuboCop or StandardRB, auto-detecting and respecting the project's config, with skip patterns for intentional bad-code examples (#74).
- **[Feature]** Added `--auto-gen-config` for incremental adoption on legacy codebases: generates `.yard-lint-todo.yml` silencing current violations (with intelligent path grouping), plus `--regenerate-todo` and `--exclude-limit N`. Inspired by RuboCop (#71).
- **[Feature]** Added an opt-in check for missing `@return` tags, excluding `initialize` by default (#70, #72, @mensfeld).

## 1.4.0 (2026-01-19)
- **[Fix]** Handle directive definitions depending on file load order (#65, @zaben903).
- **[CI]** Ruby 4.0 (stable) is now the default for dogfooding and releases; continues to support 3.2, 3.3, and 3.4.
- **[Feature]** Added `Tags/ForbiddenTags` validator (opt-in, severity `convention`) to disallow specific tag or tag+type patterns (e.g. `@return [void]`, `@param [Object]`) via a configurable `ForbiddenPatterns` list (#59).

## 1.3.0 (2025-12-10)
- **[Fix]** `Tags/Order`'s default `EnforcedOrder` now covers all standard YARD tags (previously `@note`, `@todo`, `@see`, and `@yield*` ordering was silently unvalidated).
- **[Enhancement]** `Tags/InformalNotation` now detects `IMPORTANT:`/`Important:` and suggests `@note`.
- **[Feature]** Added `Tags/TagGroupSeparator` validator (opt-in, severity `convention`) to enforce a blank line between different YARD tag groups, with an optional `RequireAfterDescription` (#29).
- **[Feature]** Added `Tags/InformalNotation` validator (enabled by default, severity `warning`) to detect patterns like `Note:`/`TODO:`/`See:` and suggest the proper YARD tag; configurable and skips fenced code blocks (#33).
- **[Feature]** Added `Tags/NonAsciiType` validator (enabled by default, severity `warning`) to detect non-ASCII characters in type specs (e.g. a smart-quote `…`), reporting the character and code point (#39).
- **[Fix]** Fixed an `Encoding::CompatibilityError` crash when YARD encounters non-ASCII characters in type specs.
- **[Fix]** Relative exclusion patterns (e.g. `vendor/**/*`) now match files discovered via absolute paths (`yard-lint .` or an absolute project path).
- **[Enhancement]** The PATH argument is now optional, defaulting to the current directory (like RuboCop).
- **[Fix]** Per-validator `YardOptions` are now respected when filtering by visibility, so a validator can override `AllValidators` defaults (#41).
- **[Feature]** Added in-process YARD execution (~10x faster) that parses files once and shares the registry, replacing per-validator subprocesses.
- **[Change]** Removed the deprecated shell execution mode and the `YARD_LINT_SHELL_MODE` variable (~1000 lines).
- **[Feature]** Added `Documentation/EmptyCommentLine` validator (enabled by default, severity `convention`) to detect leading/trailing empty `#` lines in a doc block; configurable via `EnabledPatterns`.
- **[Feature]** Added "did you mean" suggestions to `Warnings/UnknownParameterName` for mismatched parameter names, parsing actual method parameters from source.
- **[Feature]** Added "did you mean" suggestions to `Warnings/UnknownTag`, loading valid tags/directives from YARD for version compatibility (e.g. `@returns` → `@return`).
- **[Fix]** Use `#!/bin/sh` instead of `#!/bin/bash` for BSD/macOS compatibility (#34).
- **[Fix]** Fixed enhanced offense messages (e.g. "did you mean") being lost during per-validator exclusion filtering.
- **[Change]** `.yard-lint.yml` now sets `FailOnSeverity` to `convention` for stricter enforcement.
- **[CI]** Added macOS (Ruby 3.4) testing for BSD/POSIX compatibility.
- **[CI]** Added the `parallel_tests` gem for faster CI.
- **[Feature]** Added an `ArticleParamPhrase` pattern to `Tags/RedundantParamDescription` to detect filler phrases like "The action being performed", with configurable connectors and verbs (#32).
- **[Feature]** Added the `--only` CLI option to run specific validators (comma-separated), overriding `Enabled: false`, with "did you mean" suggestions.
- **[Feature]** Added `Documentation/BlankLineBeforeDefinition` validator (enabled by default, severity `convention`) to detect blank lines between YARD docs and a definition, with separate severity for orphaned (2+ line) gaps (#30).
- **[Fix]** A non-existent file path now raises `Errors::FileNotFoundError` instead of silently reporting "No offenses found".
- **[Feature]** Added the `--update` command to add new validators and remove obsolete ones in an existing `.yard-lint.yml` while preserving user configuration; supports `--strict`.
- **[Fix]** Fixed integration tests failing in parallel runs due to relative fixture paths.

## 1.2.3 (2025-11-13)
- **[Feature]** Added per-validator `Exclude` patterns, applied alongside (union with) global `AllValidators.Exclude`.
- **[Change]** `.yard-lint.yml` now sets all validator severities and `FailOnSeverity` to `error` for stricter CI enforcement.
- **[Fix]** Fixed integration tests failing because fixture files were filtered by global exclusions (added a `test_config` helper that clears them).
- **[Fix]** Removed unneeded `bin/` files.

## 1.2.2 (2025-11-13)
- **[Fix]** Fixed `--version` failing with `uninitialized constant Yard::Lint::VERSION` (a Zeitwerk naming conflict); version.rb is now loaded manually.
- **[Change]** Removed unused `net/http` and `uri` dependencies.

## 1.2.1 (2025-11-12)
- **[Fix]** Fixed help-text examples showing the wrong argument order (options before PATH).

## 1.2.0 (2025-11-12)
- **[Fix]** Added Ruby 3.5+ compatibility without requiring the IRB gem, via a lightweight `IRB::Notifier` shim that defers to the real IRB when present.
- **[Feature]** Added documentation coverage statistics with `--min-coverage PERCENT` (fails below threshold, even with no offenses) and coverage metrics under `--stats`; `MinCoverage` is also configurable and works with diff mode.
- **[Feature]** Added diff mode for incremental linting: `--diff [REF]` (auto-detecting main/master), `--staged`, and `--changed`, with `AllValidators.DiffMode` configuration. Ideal for CI and pre-commit hooks.

## 1.1.0 (2025-11-11)
- **[Feature]** Added `Tags/ExampleSyntax` validator (enabled by default, severity `warning`) to check Ruby syntax in `@example` tags, stripping output markers and skipping incomplete snippets.
- **[Feature]** Added `Tags/RedundantParamDescription` validator (enabled by default, severity `convention`) to detect meaningless parameter descriptions across seven configurable patterns, with word-count and length thresholds to avoid false positives.
- **[Feature]** Added the `--init` command to generate a `.yard-lint.yml` with sensible defaults, plus `--force` to overwrite.
- **[Feature]** Added an `EnforcedStyle` option to `Tags/CollectionType` for bidirectional Hash style enforcement (`Hash{K => V}` vs `{K => V}`).
- **[Feature]** Added `Documentation/UndocumentedOptions` validator to detect options-hash parameters (`options = {}`, `**kwargs`, etc.) lacking `@option` tags.
- **[Feature]** Added `Documentation/MarkdownSyntax` validator to detect common markdown errors (unclosed backticks, code blocks, bold; invalid list markers).
- **[Enhancement]** Condensed the alternative-style examples in the README.
- **[Documentation]** Added a Quick Start section and updated CLI help for `--init`/`--force`.

## 1.0.0 (2025-11-09)
- **[Fix]** Fixed "Argument list too long" on large codebases by using an xargs pattern with temporary file lists.
- **[Enhancement]** Expanded default exclusions to typical Ruby/Rails directories (`test/`, `log/`, `coverage/`, `db/migrate/`, etc.).
- **[Feature]** Added `Tags/TypeSyntax` validator to detect malformed YARD type syntax (unclosed brackets, empty generics, malformed hashes) via YARD's parser.
- **[Feature]** Added `Tags/MeaninglessTag` validator to detect `@param`/`@option` tags on non-method objects (classes, modules, constants).
- **[Feature]** Added `Tags/CollectionType` validator to enforce `Hash{K => V}` over `Hash<K, V>`, with correction suggestions.
- **[Feature]** Added `Tags/TagTypePosition` validator to check type-annotation position (`type_after_name` vs `type_first`) on `@param`/`@option`, reading source directly.
- **[Fix]** Fixed `Warnings/UnknownParameterName` showing only the line number instead of the full file path.
- **[Documentation]** Expanded the README (troubleshooting for `ExcludedMethods`) and documented cache clearing in `bin/yard-lint`.

## 0.2.2 (2025-11-07)
- **[Feature]** Added the `ExcludedMethods` option (simple names, `/regex/`, or arity notation; excludes parameter-less `initialize/0` by default).
- **[Fix]** `UndocumentedObjects` no longer flags methods with a `@return [Boolean]` tag as undocumented.
- **[Fix]** `UndocumentedBooleanMethods` no longer flags methods documented with `@return [Boolean]` (type without description).
- **[Enhancement]** Isolate the YARD database per argument set (SHA256 of arguments) to prevent contamination between validators, removing the previous file-filtering workaround.
- **[Change]** YARD database directories are now created under a base temp directory with unique per-argument subdirectories.

## 0.2.1 (2025-11-07)
- Release to validate the Trusted Publishing flow.

## 0.2.0 (2025-11-07)
- Initial release of the YARD-Lint gem: a CLI (`yard-lint`) and Ruby API for validating YARD documentation - undocumented objects, parameters, tag types, tag order, boolean methods, and YARD warnings - with text/JSON output, three severity levels, `.yard-lint.yml` configuration (discovery, exclusions, severity-based exit codes), `--quiet`/`--stats`, and Zeitwerk loading.

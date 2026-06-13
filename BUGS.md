# yard-lint Bug Audit

Findings from a full-codebase audit focused on **false positives** and **unexpected behavior**.
Most findings were verified by reproduction against the actual CLI/classes (Ruby 3.2/3.3, YARD 0.9.44);
confidence is noted per bug. Grouped by component; IDs are stable so we can tackle them one at a time.

## Index

### High severity
- [x] BUG-001 — `config_or_default` ignores user-set `false` values (framework-wide)
- [x] BUG-002 — `Tags/Order` & `Tags/TagGroupSeparator` silently skip all classes/modules (swallowed NameError)
- [x] BUG-003 — Location regex drops offenses for classes/constants/top-level methods
- [x] BUG-004 — `Tags/Order` parser misattributes expected-order messages (index-zip misalignment)
- [x] BUG-005 — `@overload`-nested tags invisible to 4 validators (false positives on documented code)
- [x] BUG-006 — `@option` tag data read from wrong accessors (`tag.types`/`tag.text` are nil for OptionTag)
- [x] BUG-007 — Duplicate identical offenses for `attr_accessor` docstrings (no dedup)
- [x] BUG-008 — Offenses report the `def` line instead of the offending docstring line
- [x] BUG-009 — Shipped `default_config.yml` template diverges from code defaults (5 validators)
- [ ] BUG-010 — `--update` silently deletes `inherit_from` — entire todo baseline reappears
- [ ] BUG-011 — Todo baseline broken on creation when main config has per-validator `Exclude`
- [ ] BUG-012 — `Exclude` patterns resolved against inconsistent base directories
- [ ] BUG-013 — Globally excluded files counted in coverage when linting a subdirectory
- [ ] BUG-014 — Diff modes silently lint nothing from a repo subdirectory
- [x] BUG-015 — YAML anchors/aliases in config crash with raw Psych backtrace
- [x] BUG-030 — `UndocumentedMethodArguments` counts `&block`/`*splat` params
- [ ] BUG-031 — `UndocumentedBooleanMethods` only fires on *documented* predicates, with mangled output
- [ ] BUG-033 — `MarkdownSyntax` flags `**` in plain prose (globs, exponentiation, `**kwargs`)
- [ ] BUG-034 — `MarkdownSyntax` counts backticks inside fenced code blocks
- [ ] BUG-035 — `OrphanedDocComment` scans heredoc/string content as comments
- [ ] BUG-036 — `OrphanedDocComment` DSL gaps: `memoize def`, receiver DSL calls, `@method` tags
- [ ] BUG-044 — `CollectionType` substring-matches custom classes (`MyHash<...>`)
- [ ] BUG-045 — `ExampleSyntax` corrupts string literals when stripping `# =>` markers
- [ ] BUG-046 — `ExampleSyntax` flags irb transcripts and non-Ruby `@example` bodies
- [ ] BUG-047 — `ApiTags` flags `@api private` with continuation line; corrupts parser stream
- [ ] BUG-049 — Unnamed `@example` shifts parser fields in ExampleSyntax/ExampleStyle
- [ ] BUG-053 — `InvalidTypes` can never catch misspelled class names (its core use case)
- [x] BUG-056 — `RedundantParamDescription` treats any word starting with "a"/"the" as an article
- [ ] BUG-057 — `RedundantParamDescription` `ParamToVerb` fires on "X to Y" without verb check
- [x] BUG-058 — `TagGroupSeparator` treats `@ivar` lines inside `@example` bodies as tags
- [ ] BUG-062 — `TagTypePosition` raw-comment scan misfires (example bodies, detached comments, `@option`)
- [ ] BUG-065 — Custom tags from `.yardopts`/plugins always flagged as `UnknownTag`
- [ ] BUG-079 — IRB notifier shim breaks YARD's lexer on Ruby 3.5+ — docstrings silently destroyed, FPs
- [ ] BUG-082 — Files with syntax errors silently skipped; run can exit 0
- [ ] BUG-083 — `StatsCalculator` reports 100% coverage when the `yard` subprocess fails
- [ ] BUG-085 — `PathGrouper` emits unusable `./**/*` pattern — todo file fails to exclude root offenses

### Medium severity
- [x] BUG-016 — Diamond config inheritance falsely raises `CircularDependencyError`
- [ ] BUG-017 — `-c <missing file>` crashes with raw backtrace
- [ ] BUG-018 — `--auto-gen-config` destroys all comments in `.yard-lint.yml`
- [x] BUG-019 — Missing `inherit_from` targets silently ignored
- [ ] BUG-020 — `DiffMode.DefaultBaseRef` is dead config
- [ ] BUG-021 — Category-level config (`Documentation: Enabled: false`) validated but ignored
- [ ] BUG-022 — `--diff` swallows the PATH argument as its optional REF
- [ ] BUG-023 — `--update` / `--auto-gen-config` ignore or mis-target `-c CONFIG`
- [ ] BUG-032 — `UndocumentedOptions` fires on any scalar param named `option`/`opts`; no escape for documented `**kwargs`
- [ ] BUG-037 — `OrphanedDocComment` doc line starting with `encoding:` splits the block
- [ ] BUG-038 — `BlankLineBeforeDefinition` treats shebangs/Sorbet sigils/rubocop directives as docs
- [ ] BUG-039 — `EmptyCommentLine` attributes blank-line-separated file headers to definitions
- [x] BUG-040 — `UndocumentedObjects` `ExcludedMethods` silently matches classes/modules/constants
- [ ] BUG-041 — `UndocumentedMethodArguments` double-reports fully undocumented methods; count-only check
- [ ] BUG-048 — `ApiTags` requires `@api` on constants (docs promise classes/modules/methods only)
- [ ] BUG-050 — `CollectionType` suggestion mangles nested `Hash<...>` types
- [ ] BUG-051 — `InformalNotation` matches inside 4-space-indented Markdown code blocks
- [ ] BUG-054 — `ExampleStyle`: noisy default cops, StandardRB ignores `DisabledCops`, silent linter failures
- [x] BUG-059 — `MissingYield` flags keyword/hash keys named `yield:`
- [ ] BUG-060 — `MissingYield` attributes nested `def`'s yield to enclosing method
- [ ] BUG-061 — `AbstractMethods` flags multiline `raise NotImplementedError, "msg"`
- [ ] BUG-063 — `AbstractMethods` `AllowedImplementations` config key is dead
- [ ] BUG-064 — `AbstractMethods`/`OptionTags` offenses missing the `:validator` field
- [ ] BUG-066 — Levenshtein fallback produces absurd "did you mean" suggestions for short names
- [ ] BUG-067 — `UnknownTag` suggests directive names as plain tags (`@parse` instead of `@!parse`)
- [ ] BUG-068 — `UnknownParameterName` suggestion engine reads params from the wrong method
- [ ] BUG-069 — Dead `yard list` fallback shells out per offense and litters CWD with `.yardoc`
- [ ] BUG-070 — Param suggestion source-parsing misses `def self.foo` / operator defs
- [ ] BUG-071 — `extract_parameter_names` mangles keyword defaults containing commas
- [ ] BUG-072 — One-line warning parsers break on paths containing `line ` / ` in file `
- [ ] BUG-073 — `Tags/OptionTags` flags non-hash params that merely have a matching name
- [ ] BUG-074 — `NonAsciiType` flags non-ASCII inside string-literal types
- [ ] BUG-075 — YARD logger level not restored if parse raises
- [ ] BUG-080 — Diff modes silently skip filenames with non-ASCII characters (git quotepath)
- [ ] BUG-081 — `--changed` mode ignores untracked files
- [ ] BUG-084 — Composite child results dropped when parent validator is disabled

### Low severity / notes
- [ ] BUG-024 — `Severity: never` semantics inconsistent (stats vs exit code)
- [ ] BUG-025 — Error message suggests nonexistent `--list-validators` flag
- [ ] BUG-026 — `start_with?(working_dir)` prefix matching without trailing `/`
- [ ] BUG-027 — Unknown `--format` validated only after the full lint run
- [ ] BUG-028 — Dead severity fallback in `Results::Base`
- [ ] BUG-029 — Unrescued `OptionParser::InvalidOption` dumps backtrace on unknown flags
- [ ] BUG-042 — Docstring-content validators never check tag text; `TextSubstitution` checks inline code spans
- [ ] BUG-043 — `OrphanedDocComment` never scans files with no registry objects
- [ ] BUG-052 — `InformalNotation` maps `Warning:` to `@deprecated` instead of `@note`
- [ ] BUG-055 — `ExampleSyntax`: silent no-op on JRuby/TruffleRuby; skip-heuristic false negatives
- [ ] BUG-076 — `Tags/Order`: explicit `EnforcedOrder: ~` crashes the run
- [ ] BUG-077 — `MeaninglessTag` flags `Data.define` `@param` docs on older YARD 0.9.x
- [ ] BUG-078 — Invalid UTF-8 sources silently skipped per object (hidden false negatives)
- [ ] BUG-086 — Cross-thread warning attribution via process-global YARD logger (theoretical)

---

## 1. Cross-cutting / framework

### BUG-001: `config_or_default` ignores user-set `false` values
- **Location**: `lib/yard/lint/validators/base.rb:239`
- **Category**: wrong-behavior · **Confidence**: high (reproduced independently by two auditors)

`config.validator_config(validator_name, key) || defaults[key]` — `false || default` returns the
default, so any boolean key whose default is truthy cannot be disabled. Verified:
`Tags/InformalNotation: RequireStartOfLine: false` has no effect. Affects every boolean option read
through this shared helper. Fix: key-presence check (`nil?`-based dig) instead of `||`.

### BUG-002: `Tags/Order` and `Tags/TagGroupSeparator` silently skip all classes/modules/constants
- **Location**: `lib/yard/lint/validators/tags/order/validator.rb:20`, `lib/yard/lint/validators/tags/tag_group_separator/validator.rb:24`; enabling rescue at `lib/yard/lint/executor/query_executor.rb`
- **Category**: false-negative / wrong-behavior · **Confidence**: high (verified live)

Both call `return if object.is_alias?` before type-checking. On non-method objects YARD's
`method_missing` raises **NameError** (not NoMethodError), which `QueryExecutor` swallows under its
broad `StandardError` rescue. Class-level docstrings are never checked by these validators; with
`DEBUG=1` the swallowed NameError prints for every namespace object. Fix: check
`object.type == :method` first (as `missing_yield` does). Consider also narrowing the executor
rescue so validator bugs like this surface.

### BUG-003: Location regex drops offenses for classes/constants/top-level methods
- **Location**: `lib/yard/lint/validators/documentation/undocumented_method_arguments/parser.rb:14`, `lib/yard/lint/validators/tags/invalid_types/parser.rb:14`
- **Category**: false-negative / wrong-behavior · **Confidence**: high (verified live)

`LOCATION_REGEX = /^(.+):(\d+):\s+(.+)[#.](.+)$/` requires a `#` or `.` in the object title.
Top-level methods (`#foo` — no character before the separator) and class/module/constant titles
(`Foo::Bar`, `CONST`) never match, so their offenses are silently discarded. Verified for
UndocumentedMethodArguments, InvalidTypes (top-level method + constant), and Tags/Order (via the
shared parser). Downstream consumers that zip arrays by index also get misaligned (BUG-004).
Correction during fixing: MissingReturn was originally listed here but its parser uses a different
regex (`(.+?)\|`) that handles top-level titles correctly — the audit repro was fooled by the
validator being disabled by default.

### BUG-004: `Tags/Order` parser misattributes expected-order strings and drops offenses
- **Location**: `lib/yard/lint/validators/tags/order/parser.rb` (index-zip with locations from the UndocumentedMethodArguments parser); same pattern in `tag_group_separator/parser.rb`
- **Category**: wrong-behavior + false-negative · **Confidence**: high (verified live)

Two parallel arrays (locations, expected-order strings) are zipped by index. When BUG-003 drops a
location (e.g. a top-level method), every subsequent offense is paired with the *previous* entry's
expected-order message. Verified: `Foo#m` reported with the top-level method's expected order.

### BUG-005: `@overload`-nested tags invisible to 4 validators — false positives on documented code
- **Location**: `documentation/missing_return/validator.rb:27`, `documentation/undocumented_method_arguments/validator.rb:31-32`, `tags/option_tags/validator.rb`, `tags/forbidden_tags/validator.rb:21`
- **Category**: false-positive (MissingReturn, UndocumentedMethodArguments, OptionTags) / false-negative (ForbiddenTags) · **Confidence**: high (verified live)

YARD stores tags written inside `@overload` blocks on the overload's own docstring;
`object.tag(:return)` / `object.tags(:param)` / `object.tags(:option)` / `docstring.tags` don't see
them. A method fully documented via `@overload` is flagged for missing `@return`, missing `@param`s,
and missing `@option`s; forbidden tags inside overloads escape detection. The framework already
provides `Validators::Base#all_typed_tags` (`validators/base.rb:88`) for exactly this — unused.

### BUG-006: `@option` tag data read from the wrong accessors — `option` entries in `ValidatedTags`/`CheckedTags` are dead
- **Location**: `tags/invalid_types/validator.rb:42`, `tags/collection_type/validator.rb:23-25`, `tags/forbidden_tags/validator.rb:48,57`, `tags/redundant_param_description/validator.rb`
- **Category**: false-negative / dead config · **Confidence**: high (verified live)

For YARD's `OptionTag`, `tag.types` and `tag.text` are `nil` — real data lives on `tag.pair.types`
/ `tag.pair.text`. InvalidTypes, CollectionType, and ForbiddenTags never validate `@option` types
(`@option opts [notaclass] :x` passes); RedundantParamDescription never checks `@option`
descriptions despite `CheckedTags: [param, option]`.

### BUG-007: Duplicate identical offenses for `attr_accessor` docstrings
- **Location**: no dedup anywhere — `executor/warning_dispatcher.rb`, `result_builder.rb`, `results/base.rb`; docstring validators iterate per generated method (e.g. `documentation/line_length/validator.rb:20-40`)
- **Category**: wrong-behavior · **Confidence**: high (verified live, two independent paths)

One docstring on `attr_accessor :value` produces two identical offenses — once for `#value`, once
for `#value=` — both via YARD warning capture (UnknownTag etc.) and via docstring-content validators
(LineLength, MarkdownSyntax, TextSubstitution). Offense counts inflate. Fix: dedupe identical
(validator, file, line, message) tuples in the result pipeline.

### BUG-008: Offenses report the `def` line, not the offending docstring line
- **Location**: `documentation/text_substitution/validator.rb:27`, `tags/informal_notation/validator.rb:36` (computes `line_offset`, never uses it), `documentation/markdown_syntax` (`invalid_list_marker:N` is docstring-relative)
- **Category**: wrong-behavior (wrong line numbers) · **Confidence**: high (verified live)

Validators that scan docstring text emit `object.line` even when they know the exact offending
docstring line. Verified: em-dash on source line 3 reported at line 6. `docstring.line_range`
(already used by LineLength) gives the real base. InformalNotation threads `line_offset` all the
way through and then drops it.

### BUG-009: Shipped `default_config.yml` diverges from code defaults — `--init` silently changes behavior
- **Location**: `lib/yard/lint/templates/default_config.yml` vs `tags/type_syntax/config.rb`, `tags/non_ascii_type/config.rb`, `tags/invalid_types/config.rb`, `tags/collection_type/config.rb`, `tags/informal_notation/config.rb`
- **Category**: wrong-behavior / false-negative · **Confidence**: high

Because validator-config arrays/hashes are **replaced**, not merged, a project that materialized
the template via `--init` gets different behavior than one with no config at all:
- TypeSyntax: template drops `yieldparam`, `raise` from `ValidatedTags`
- NonAsciiType: template drops `raise`
- InvalidTypes: template drops `yieldreturn`, `yieldparam`, `raise`
- CollectionType: template drops `yieldparam`, `raise`
- InformalNotation: template `Patterns` omits `IMPORTANT`/`Important`

Also: in-code fallback literals in `type_syntax/validator.rb` and `non_ascii_type/validator.rb`
differ from their own `Config.defaults` (currently dead, but a trap).

## 2. Config, CLI & file selection

### BUG-010: `--update` silently deletes `inherit_from` — entire todo baseline reappears
- **Location**: `lib/yard/lint/config_updater.rb:87-123, 155-187`; `bin/yard-lint:147-168`
- **Category**: wrong-behavior · **Confidence**: high (reproduced end-to-end)

`merge_configs` rebuilds the config from `AllValidators` + template keys only; `inherit_from` /
`inherit_gem` are never copied and never written. Repro: `--auto-gen-config` → clean run →
`--update` → `inherit_from: [.yard-lint-todo.yml]` gone, all baselined offenses back.

### BUG-011: Todo baseline broken on creation when main config has per-validator `Exclude`
- **Location**: `lib/yard/lint/todo_generator.rb:78-107`; `lib/yard/lint/config_loader.rb:184-191`
- **Category**: wrong-behavior / false-positive · **Confidence**: high (reproduced)

(a) `run_linting` bypasses `Runner#filter_result_offenses`, so already-excluded offenses are counted
and written into the todo file. (b) Inheritance merging replaces arrays wholesale (no
`inherit_mode: merge` support), so a main-config `Exclude` clobbers the inherited todo `Exclude`.
Net effect: immediately after generation the tool promises "you should see no offenses", and the
next run reports the supposedly-baselined offense.

### BUG-012: `Exclude` patterns resolved against inconsistent base directories
- **Location**: `lib/yard/lint/runner.rb:127-143` (`Dir.pwd`) vs `lib/yard/lint.rb:142-148,156-186` (lint target dir); `runner.rb:101-110` (absolute paths never match relative patterns)
- **Category**: false-positive · **Confidence**: high (reproduced)

Per-validator/todo excludes are relativized against `Dir.pwd`; global excludes against the target
path. Running `yard-lint -c proj/.yard-lint.yml proj` from outside the project (CI, editor
integrations) makes all per-validator and todo exclusions stop matching → baselined offenses
reappear. Patterns should anchor to the config file's directory (RuboCop semantics).

### BUG-013: Globally excluded files parsed and counted in coverage when linting a subdirectory
- **Location**: `lib/yard/lint.rb:98-109, 142-148`
- **Category**: wrong-behavior (spurious `MinCoverage` failures) · **Confidence**: high (reproduced)

With `AllValidators: Exclude: ['lib/legacy/**/*']`, `yard-lint .` reports 100% coverage but
`yard-lint lib` reports 33% — the pattern base becomes `<proj>/lib`, the root-relative pattern no
longer matches, and excluded files enter the coverage denominator. A `MinCoverage` gate flips
depending on whether the user typed `.` or `lib`.

### BUG-014: Diff modes silently lint nothing from a repo subdirectory
- **Location**: `lib/yard/lint/git.rb:100-108`
- **Category**: false-negative (silent) · **Confidence**: high (reproduced)

`git diff --name-only` outputs repo-root-relative paths, but `filter_ruby_files` expands them
against the **cwd**. From `<repo>/backend`, `backend/lib/a.rb` becomes
`<repo>/backend/backend/lib/a.rb`, fails `File.exist?`, and is dropped. `--diff/--staged/--changed`
from any subdirectory reports "No offenses found" while changes exist. Expand against
`git rev-parse --show-toplevel`.

### BUG-015: YAML anchors/aliases in config crash with raw Psych backtrace
- **Location**: `lib/yard/lint/config_loader.rb:120` (also `config_updater.rb:72`, `todo_generator.rb:209`)
- **Category**: crash · **Confidence**: high (reproduced)

Ruby ≥ 3.2 / Psych 4 rejects aliases in `YAML.load_file` by default. The common RuboCop idiom
(`common: &common` / `<<: *common`) aborts with unrescued `Psych::AliasesNotEnabled`. Malformed YAML
(`Psych::SyntaxError`) likewise escapes as a raw backtrace. Fix: `aliases: true` + rescue Psych errors.

### BUG-016: Diamond config inheritance falsely raises `CircularDependencyError`
- **Location**: `lib/yard/lint/config_loader.rb:112-118`
- **Category**: crash (false positive on cycle check) · **Confidence**: high (reproduced)

`@loaded_files` is append-only — a "seen" set used where a recursion stack is needed.
`inherit_from: [a.yml, b.yml]` where both inherit `common.yml` raises although there is no cycle.

### BUG-017: `-c <missing file>` crashes with a raw backtrace
- **Location**: `bin/yard-lint:222-231` (rescues only `InvalidConfigError`); `bin/yard-lint:171-203` rescues `FileNotFoundError` which is a *sibling*, not parent, of `ConfigFileNotFoundError` (`errors.rb:11,20`)
- **Category**: crash · **Confidence**: high (reproduced)

`yard-lint -c /nonexistent.yml .` → unrescued `ConfigFileNotFoundError` with full backtrace. Same
hole in the `--auto-gen-config` branch.

### BUG-018: `--auto-gen-config` rewrites `.yard-lint.yml` via `to_yaml`, destroying all comments
- **Location**: `lib/yard/lint/todo_generator.rb:208-219`
- **Category**: wrong-behavior (destructive) · **Confidence**: high (reproduced)

Adding `inherit_from` round-trips the whole config through `YAML.load_file(...).to_yaml` — every
comment is deleted and the file reformatted. RuboCop prepends the line textually for this reason.

### BUG-019: Missing `inherit_from` targets silently ignored
- **Location**: `lib/yard/lint/config_loader.rb:140-145`
- **Category**: wrong-behavior → mass false positives · **Confidence**: high (reproduced)

`if File.exist?(inherited_path)` has no else branch. A renamed/deleted/typoed
`.yard-lint-todo.yml` makes the entire baseline silently evaporate with no indication why.

### BUG-020: `AllValidators.DiffMode.DefaultBaseRef` is dead config
- **Location**: `lib/yard/lint/config.rb:140-143` (zero callers) vs `lib/yard/lint.rb:79-88`, `lib/yard/lint/git.rb:34-36`
- **Category**: wrong-behavior (documented setting ignored) · **Confidence**: high

The shipped template advertises `DefaultBaseRef`, but `--diff` with no REF goes straight to
auto-detection of main/master. Setting `DefaultBaseRef: develop` does nothing — wrong file set
linted, or "Could not detect default branch" errors on exactly the repos that need this option.

### BUG-021: Category-level config (`Documentation: Enabled: false`) validates but is silently ignored
- **Location**: `lib/yard/lint/config_validator.rb:58-59` vs `lib/yard/lint/config.rb:269-274`
- **Category**: false-positive (disabled validators still report) · **Confidence**: high (reproduced)

The validator whitelists category root keys, implying department-level config works — but
`build_validators_config` only processes keys containing `/`. Either implement it or reject the key.

### BUG-022: `--diff` swallows the PATH argument as its optional REF
- **Location**: `bin/yard-lint:47-49` (`opts.on('--diff [REF]')`)
- **Category**: wrong-behavior · **Confidence**: high (verified semantics)

`yard-lint --diff lib/` parses `lib/` as the git REF → "unknown revision" error instead of linting
changed files under `lib/`.

### BUG-023: `--update` and `--auto-gen-config` ignore or mis-target `-c CONFIG`
- **Location**: `bin/yard-lint:147-168` + `config_updater.rb:35` (hardcodes `Dir.pwd/.yard-lint.yml`); `todo_generator.rb:32-33`
- **Category**: wrong-behavior · **Confidence**: high

`--update -c configs/lint.yml` updates `./.yard-lint.yml` instead. `--auto-gen-config -c ...`
generates the todo from the custom config but links `inherit_from` into a *new* `./.yard-lint.yml`,
which then shadows the custom config on future plain runs.

### BUG-024: `Severity: never` semantics inconsistent
- **Location**: `lib/yard/lint/results/aggregate.rb:48-101`
- **Category**: wrong-behavior · **Confidence**: low (intent unclear)

`never`-severity offenses are omitted from the error/warning/convention breakdown (stats don't sum
to total) yet still trigger exit code 1 under `FailOnSeverity: convention` via `offenses.any?`.

### BUG-025: Error message suggests nonexistent `--list-validators` flag
- **Location**: `lib/yard/lint/config_validator.rb:205`
- **Category**: wrong-behavior (UX) · **Confidence**: high

Following the advice yields an invalid-option failure (see also BUG-029).

### BUG-026: `start_with?(working_dir)` prefix matching without trailing `/`
- **Location**: `lib/yard/lint/runner.rb:134`, `lib/yard/lint/todo_generator.rb:137`
- **Category**: wrong-behavior · **Confidence**: medium (unlikely in practice)

`/repo` vs `/repo2/...` mismatch leaves paths absolute so relative exclude patterns can't match.

### BUG-027: Unknown `--format` validated only after the full lint run
- **Location**: `bin/yard-lint:283-360`
- **Category**: wrong-behavior (UX) · **Confidence**: high

`yard-lint --format xml` performs the entire run, then prints "Unknown format" and exits 1.

### BUG-028: Dead severity fallback in `Results::Base`
- **Location**: `lib/yard/lint/results/base.rb:146` vs `config.rb:167`
- **Category**: latent wrong-behavior · **Confidence**: high (currently unmanifested)

`config.validator_severity(...)` can never return nil (falls back to `'warning'`), so a future
validator omitting `Severity` from defaults silently gets `warning` instead of its Result class's
`default_severity`.

### BUG-029: Unrescued `OptionParser::InvalidOption` dumps backtrace on unknown flags
- **Location**: `bin/yard-lint:128`
- **Category**: crash (UX) · **Confidence**: high

## 3. Documentation validators

### BUG-030: `UndocumentedMethodArguments` counts `&block`/`*splat` params
- **Location**: `documentation/undocumented_method_arguments/validator.rb:31`
- **Category**: false-positive · **Confidence**: high (verified)

`object.parameters.size` includes `&block`/`*splat`, while every other arity computation in the gem
excludes them. A block documented per YARD convention with `@yield` is still demanded as `@param`.
(See also BUG-005 for the `@overload` variant.)

### BUG-031: `UndocumentedBooleanMethods` only ever fires on *documented* predicates, with mangled output
- **Location**: `documentation/undocumented_boolean_methods/validator.rb:30`, `parser.rb:14,34`
- **Category**: false-positive + wrong-behavior + inherent false-negative · **Confidence**: high (verified)

(1) YARD auto-adds `@return [Boolean]` to every `?` method *except* when an `@overload` carries the
`@return` — so the nil/empty check is never true for undocumented predicates and true precisely for
predicates documented via `@overload`. The validator can only flag correct documentation.
(2) When it fires, the parser regex expects bare `Class#method` but gets `file:line: Class#method`:
the file path leaks into the element name and line is hardcoded 0.

### BUG-032: `UndocumentedOptions` fires on any scalar param named `option`/`opt`/`opts`/`options`; documented `**kwargs` has no escape
- **Location**: `documentation/undocumented_options/validator.rb:29`
- **Category**: false-positive · **Confidence**: high (verified)

`def enable(option)` with a perfectly documented `@param option [Symbol]` is told it needs
`@option` tags. Pass-through `**kwargs` documented as an opaque `@param headers [Hash]` is also
flagged. Cosmetic: message renders `(option )` with a trailing space.

### BUG-033: `MarkdownSyntax` flags `**` in plain prose as unclosed bold
- **Location**: `documentation/markdown_syntax/validator.rb:33-35`
- **Category**: false-positive · **Confidence**: high (verified)

Odd counts of `**` outside inline code spans: glob patterns (`lib/**/*.rb`), exponentiation
(`x ** y`), mentions of `**kwargs`. Fenced code blocks are not excluded either.

### BUG-034: `MarkdownSyntax` counts backticks inside fenced code blocks
- **Location**: `documentation/markdown_syntax/validator.rb:24-26`
- **Category**: false-positive · **Confidence**: high (verified)

`scan(/`/).count` includes fence characters and code content; a fenced block containing one
backtick makes the total odd → `unclosed_backtick`.

### BUG-035: `OrphanedDocComment` scans heredoc/string content as comments
- **Location**: `documentation/orphaned_doc_comment/validator.rb:79-105`
- **Category**: false-positive · **Confidence**: high (verified)

Raw line scanning with no string/heredoc state: a heredoc line `# @param foo [String] something`
is flagged as an orphaned doc comment. Same risk for `=begin/=end` content.

### BUG-036: `OrphanedDocComment` remaining DSL/definition gaps (post-#184)
- **Location**: `documentation/orphaned_doc_comment/validator.rb:33-41`
- **Category**: false-positive · **Confidence**: high (all verified against real YARD output)

1. Wrapped defs: `memoize def value` / `module_function def` (only `private/protected/public`
   prefixes are recognized).
2. Receiver DSL calls: `MyDSL.register :name do ... end` (pattern requires a bare lowercase start).
3. `# @method dynamic_size` above a call with no symbol/string first arg (`acts_as_counter do`) —
   YARD creates the method from the tag name alone.

### BUG-037: `OrphanedDocComment` doc line starting with `encoding:` (etc.) splits the block
- **Location**: `documentation/orphaned_doc_comment/validator.rb:113-121`
- **Category**: false-positive · **Confidence**: medium (verified)

`magic_comment?` matches any comment whose text *begins with* a magic prefix anywhere in the file,
with arbitrary trailing text. `# encoding: UTF-8 is assumed for all inputs` mid-docstring
terminates the block → flagged orphaned although `def` directly follows.

### BUG-038: `BlankLineBeforeDefinition` treats shebangs/Sorbet sigils/rubocop directives as documentation
- **Location**: `documentation/blank_line_before_definition/validator.rb:46-74`
- **Category**: false-positive · **Confidence**: high (all verified)

Flags undocumented definitions below `#!/usr/bin/env ruby`, `# typed: strict`,
`# rubocop:disable ...`, and `# frozen_string_literal: true` followed by a bare `#` (the bare `#`
defeats the magic-comment skip). The suggested fix (remove the blank line) would make the directive
the docstring.

### BUG-039: `EmptyCommentLine` attributes blank-line-separated file headers to the definition
- **Location**: `documentation/empty_comment_line/validator.rb:31-44`
- **Category**: false-positive · **Confidence**: high (verified)

The upward scan skips unlimited blank lines and has no magic-comment handling — a license/header
comment ending in a bare `#` is reported as "empty trailing comment line in documentation for
'Foo'" although YARD does not attach it.

### BUG-040: `UndocumentedObjects` `ExcludedMethods` silently matches classes/modules/constants
- **Location**: `documentation/undocumented_objects/parser.rb:66`
- **Category**: wrong-behavior · **Confidence**: high (verified)

For non-method elements, `element.split(/[#.]/).last` falls back to the full object path — a
method-exclusion regex like `/cache/` suppresses "undocumented class `Memcached`".

### BUG-041: `UndocumentedMethodArguments` double-reports fully undocumented methods; count-only check
- **Location**: `documentation/undocumented_method_arguments/validator.rb:17-37`
- **Category**: wrong-behavior (noise) + false-negative · **Confidence**: medium (verified; intent ambiguous)

No docstring-presence guard, so an undocumented `def push(item)` gets both `UndocumentedObject` and
`UndocumentedMethodArgument`. The check is also count-based only: a misnamed `@param wrong_name`
satisfies it.

### BUG-042: Docstring-content validators never check tag text; `TextSubstitution` checks inline code spans
- **Location**: `documentation/markdown_syntax`, `documentation/text_substitution/validator.rb:48-52`
- **Category**: false-negative / false-positive · **Confidence**: high (verified)

Both scan `object.docstring.to_s`, which excludes tag text — an em-dash or unclosed backtick in a
`@param`/`@return` description is never checked. Conversely, TextSubstitution flags forbidden
strings inside `` `...` `` spans (only ``` fences are skipped).

### BUG-043: `OrphanedDocComment` never scans files with no registry objects
- **Location**: `documentation/orphaned_doc_comment/validator.rb:55-63`
- **Category**: false-negative · **Confidence**: high (verified)

The query is object-driven; a file containing only an orphaned tagged comment plus procedural code
yields zero offenses.

## 4. Tags & semantic validators

### BUG-044: `CollectionType` substring-matches custom classes (`MyHash<...>`)
- **Location**: `tags/collection_type/validator.rb:46,49,56-57`; `messages_builder.rb:58`
- **Category**: false-positive · **Confidence**: high (reproduced e2e)

Unanchored `/Hash<.*>/` and `/Array<.*>/`: `MyHash<String, Integer>` is flagged with the nonsense
suggestion `MyHash{String => Integer}`; `ByteArray<Integer>` misdetected as Array long style. Needs
a word-boundary anchor.

### BUG-045: `ExampleSyntax` corrupts string literals when stripping `# =>` markers
- **Location**: `tags/example_syntax/validator.rb:29`; same logic in `tags/example_style/rubocop_runner.rb:116`
- **Category**: false-positive · **Confidence**: high (reproduced e2e)

`line.sub(/\s*#\s*=>.*$/, '')` strips from any `# =>` to EOL, including inside string literals —
`msg = "result # => not output"` becomes an unterminated string and is flagged as a syntax error.
Same cleaning makes ExampleStyle's RuboCop report `Lint/Syntax` on valid code.

### BUG-046: `ExampleSyntax` flags irb transcripts and non-Ruby `@example` bodies
- **Location**: `tags/example_syntax/validator.rb:27-67`
- **Category**: false-positive · **Confidence**: high (verified)

irb-style examples (`>> 1 + 1` / `=> 2`) and non-Ruby bodies (YAML, shell, JSON) are compiled as
Ruby. The single-line skip heuristic doesn't cover multi-line cases; conversely a single-line chain
fragment like `.with_indifferent_access` is flagged.

### BUG-047: `ApiTags` flags `@api private` with a continuation line — and corrupts the parser stream
- **Location**: `tags/api_tags/validator.rb:18-23`, `parser.rb:18`
- **Category**: false-positive + wrong-behavior · **Confidence**: high (reproduced e2e)

YARD tag text includes indented continuation lines, so `@api private` + `#   internal use only`
fails the exact-match allowlist with the self-contradictory message "invalid @api tag value:
'private'". Worse, the multi-line value breaks the parser's `each_slice(2)` pairing — a later
legitimate offense was silently dropped in repro.

### BUG-048: `ApiTags` requires `@api` on constants
- **Location**: `tags/api_tags/validator.rb:42-45`
- **Category**: false-positive · **Confidence**: medium-high (reproduced e2e)

The missing-tag branch has no type filter, so every public constant gets "missing @api tag" —
the validator's own docs promise classes/modules/methods. Bites exactly the classes being newly
annotated (transitive tags cover already-annotated namespaces).

### BUG-049: Unnamed `@example` produces empty name line → parser misalignment in ExampleSyntax/ExampleStyle
- **Location**: `tags/example_syntax/validator.rb:54`, `tags/example_style/validator.rb:31`
- **Category**: wrong-behavior · **Confidence**: high (reproduced e2e)

`example.name || "Example #{index + 1}"` never falls back: real YARD returns `""` (not nil; a unit
test stubs `name: nil`, encoding the wrong assumption). The empty line is `reject(&:empty?)`-ed by
both parsers, shifting all subsequent fields — in ExampleStyle the next offense is swallowed
entirely. Fix: `example.name.to_s.empty?` fallback.

### BUG-050: `CollectionType` suggestion mangles nested `Hash<...>` types
- **Location**: `tags/collection_type/messages_builder.rb:58-62`
- **Category**: wrong-behavior (message) · **Confidence**: high (verified)

`Hash<Symbol, Hash<String, Integer>>` → suggestion `Hash{Symbol => Hash<String, Integer}>`
(mismatched braces, inner hash untouched).

### BUG-051: `InformalNotation` matches inside 4-space-indented Markdown code blocks
- **Location**: `tags/informal_notation/validator.rb:57-66`
- **Category**: false-positive · **Confidence**: high (reproduced e2e)

Only fenced ``` blocks are skipped; `Note: ...` inside an indented code block is flagged.

### BUG-052: `InformalNotation` default maps `Warning:` to `@deprecated`
- **Location**: `tags/informal_notation/config.rb:28`, `templates/default_config.yml:268`
- **Category**: wrong-behavior · **Confidence**: medium

"Warning: this can be slow" → "Use @deprecated tag" — a warning is not a deprecation (`@note` would
fit). Compounded by `CaseSensitive: false` default.

### BUG-053: `InvalidTypes` can never catch misspelled class names — its core use case
- **Location**: `tags/invalid_types/validator.rb:88-94`
- **Category**: false-negative · **Confidence**: high (verified)

`return true unless const_result.nil?` treats `const_defined?("Strng") == false` as "recognized".
Every syntactically valid constant name returns true/false (never nil), so all CamelCase typos
pass; only lowercase/garbage tokens (which raise NameError) get flagged.

### BUG-054: `ExampleStyle`: noisy default cops, StandardRB ignores `DisabledCops`, silent linter failures
- **Location**: `tags/example_style/config.rb:14-27`, `rubocop_runner.rb:152-176`
- **Category**: false-positive (noise) + false-negative (silent) · **Confidence**: medium-high

The project's `.rubocop.yml` applies to snippets, so snippet-irrelevant cops fire
(`Lint/UselessAssignment` on `result = calc.sum(1, 2)`, `Style/Documentation` on `class Foo`
snippets) — the repo's own e2e test has to disable them manually. With `standardrb`,
`DisabledCops` is silently dropped (no `--except`). Any linter failure (missing plugin gem, invalid
cop name, non-Bundler PATH rubocop) yields empty stdout → `[]` → validator silently reports nothing.

### BUG-055: `ExampleSyntax` is a silent no-op on JRuby/TruffleRuby; skip-heuristic false negatives
- **Location**: `tags/example_syntax/validator.rb:38-45`; `executor/query_executor.rb:63`
- **Category**: false-negative · **Confidence**: medium

`RubyVM::InstructionSequence` doesn't exist off MRI; the NameError is swallowed per-object. Any
single-line example starting with a lowercase word or constant (`User.find(1`) is never checked.

### BUG-056: `RedundantParamDescription`: any word starting with "a"/"an"/"the" treated as an article
- **Location**: `tags/redundant_param_description/validator.rb` (`articles_re = /^(#{articles.join('|')})/i`)
- **Category**: false-positive · **Confidence**: high (verified)

Unanchored prefix match: `@param user [User] authenticated user` and `@param id [Integer]
auto-generated id` are flagged as "just restates the parameter name" ("authenticated" starts with
"a"…). Also infects `PossessiveParam` and `ArticleParamPhrase`. Fix: `\A(...)\z` with word boundary.

### BUG-057: `RedundantParamDescription` `ParamToVerb` fires on "X to Y" without checking Y is a verb
- **Location**: `tags/redundant_param_description/validator.rb` (ParamToVerb branch)
- **Category**: false-positive · **Confidence**: high (verified)

`@param path [String] path to file` → "too generic". The configured `LowValueVerbs` list is never
consulted by this branch.

### BUG-058: `TagGroupSeparator` treats `@ivar` lines inside `@example` bodies as tags
- **Location**: `tags/tag_group_separator/validator.rb` (`stripped.start_with?('@')`)
- **Category**: false-positive · **Confidence**: high (verified)

`#   @result = compute` inside an example → "missing a blank line between `example` and `result`
tag groups". Should require `@` at column 0 of the unstripped line (as `Tags/Order` does).

### BUG-059: `MissingYield` flags symbol hash keys / keyword args named `yield:`
- **Location**: `tags/missing_yield/validator.rb:129` (`YIELD_PATTERN`)
- **Category**: false-positive · **Confidence**: high (verified)

The lookbehind guards `:yield`/`.yield` but not the label form: `{ yield: true }` is flagged as
yielding. Add a negative lookahead for `:` (careful with `yield ::Foo`).

### BUG-060: `MissingYield` attributes a nested `def`'s yield to the enclosing method
- **Location**: `tags/missing_yield/validator.rb` (`source_contains_yield?` scans full `object.source`)
- **Category**: false-positive · **Confidence**: medium (verified; uncommon shape)

`def outer; def inner; yield 1; end; end` flags `#outer` though only `inner` yields.

### BUG-061: `AbstractMethods` flags multiline `raise NotImplementedError, "message"`
- **Location**: `semantic/abstract_methods/validator.rb` (per-line heuristic)
- **Category**: false-positive (+ noted false-negatives) · **Confidence**: high (verified)

A raise whose message continues on the next line leaves a bare string-literal line that counts as
"real implementation". Converse: any line containing the substring `raise` is excused (so
`raise ArgumentError` bodies never flag), and endless/one-line defs are never flagged.

### BUG-062: `TagTypePosition` raw-comment scan misfires
- **Location**: `tags/tag_type_position/validator.rb` (`in_process_query`)
- **Category**: false-positive · **Confidence**: high (verified)

(a) tag-like text inside `@example` bodies is flagged as a mis-positioned real tag;
(b) blank lines don't terminate the upward scan, so detached comment blocks YARD doesn't attach
are still attributed to the method; (c) under `EnforcedStyle: type_first`, every valid `@option`
tag is flagged with the nonsensical suggestion `@option [Boolean] opts` — name-first is the only
valid `@option` grammar. Minor: docstrings >50 lines partially scanned; `def` on a file's last
line skipped.

### BUG-063: `AbstractMethods` `AllowedImplementations` config key is dead
- **Location**: `semantic/abstract_methods/config.rb:14` vs `validator.rb`
- **Category**: dead config · **Confidence**: high

Defined in defaults (and asserted by a test) but never read — customizing it silently does nothing.

### BUG-064: `AbstractMethods` and `OptionTags` offenses missing the `:validator` field
- **Location**: `semantic/abstract_methods/result.rb`, `tags/option_tags/result.rb`
- **Category**: wrong-behavior · **Confidence**: high (verified)

Both override `build_offenses` and omit `validator: validator_name`; the CLI prints an empty
validator name for these offenses.

### BUG-073: `Tags/OptionTags` flags non-hash parameters that merely have a matching name
- **Location**: `tags/option_tags/validator.rb`
- **Category**: false-positive · **Confidence**: medium (verified; heuristic by design)

Name-only check with `:`/`*` stripped: `def run(options: false)` (boolean kwarg) and `def run(opts)`
documented as `Array<String>` are forced to add `@option` tags. Could consult the documented
`@param` type or default value.

### BUG-074: `NonAsciiType` flags non-ASCII inside string-literal types
- **Location**: `tags/non_ascii_type/validator.rb:404-423`
- **Category**: false-positive · **Confidence**: medium (verified)

`@param mode ["naïve", "plain"]` → "Ruby type names must use ASCII" — but `"naïve"` is a string
*value*, not a type name. Apply the same literal-skip regexes TypeSyntax already uses.

### BUG-076: `Tags/Order`: explicit `EnforcedOrder: ~` (null) crashes the run
- **Location**: `tags/order/validator.rb` (`tags_order` → `order = tags_order.dup`)
- **Category**: crash · **Confidence**: low (defaults normally mask it)

A user YAML containing `EnforcedOrder:` overrides the seeded array with nil → `nil.dup` raises and
`QueryExecutor` re-raises NoMethodError, aborting the entire run.

### BUG-077: `MeaninglessTag` flags `Data.define` `@param` docs on older YARD 0.9.x
- **Location**: `tags/meaningless_tag/`
- **Category**: false-positive · **Confidence**: low (gemspec allows `yard ~> 0.9`)

On YARD versions without the Data handler, `Foo = Data.define(...)` is a `:constant`, so its
legitimate `@param` tags get flagged.

## 5. Warnings validators (YARD warning capture)

### BUG-065: Custom tags registered via `.yardopts` / YARD plugins are still flagged as UnknownTag
- **Location**: `executor/in_process_registry.rb:26-66`; affects `warnings/unknown_tag/`
- **Category**: false-positive · **Confidence**: high (reproduced)

The in-process executor never loads `.yardopts` (`--tag` entries) or `YARD::Config.load_plugins`.
A project whose plain `yard` run accepts `@custom_tag` gets `Warnings/UnknownTag` from yard-lint,
with no escape hatch other than disabling the validator.

### BUG-066: Levenshtein fallback produces absurd "did you mean" suggestions for short names
- **Location**: `warnings/unknown_tag/messages_builder.rb:94-108`; copy-pasted at `warnings/unknown_parameter_name/messages_builder.rb:193-208`
- **Category**: wrong-behavior · **Confidence**: high (reproduced)

`max_distance = max(len)/2` allows ~60%-different candidates for short names: `@foo` → "did you
mean '@todo'?", `@spec` → "did you mean '@see'?".

### BUG-067: `UnknownTag` suggests directive names as plain tags
- **Location**: `warnings/unknown_tag/messages_builder.rb:42,74`
- **Category**: wrong-behavior · **Confidence**: high (reproduced)

Directives are merged into the dictionary but rendered with a plain `@`: `@parsee` → "did you mean
'@parse'?" — following that advice produces another UnknownTag offense. Render as `@!parse` or
exclude directive-only names.

### BUG-068: `UnknownParameterName` suggestion engine reads parameters from the wrong method
- **Location**: `warnings/unknown_parameter_name/messages_builder.rb:73-101`
- **Category**: wrong-behavior · **Confidence**: high (reproduced)

The scan starts at `line - 15` and returns the *first* `def` found — any method defined in the
preceding 15 lines wins, suppressing correct suggestions (or enabling wrong ones). Start at the
reported line.

### BUG-069: Dead `yard list` fallback: always returns `[]`, shells out per offense, litters CWD with `.yardoc`
- **Location**: `warnings/unknown_parameter_name/messages_builder.rb:149-165`
- **Category**: wrong-behavior · **Confidence**: high (reproduced)

Parses the entire project via subprocess, unconditionally returns `[]`, creates `.yardoc/` in the
working directory as a side effect, and has broken quoting (Shellwords inside single quotes).
Delete it.

### BUG-070: Param suggestion source-parsing misses `def self.foo`, `def obj.foo`, operator defs
- **Location**: `warnings/unknown_parameter_name/messages_builder.rb:96-100` (`/^\s*def\s+\w+\s*\(/`)
- **Category**: false-negative (also triggers BUG-069's subprocess) · **Confidence**: high (reproduced)

### BUG-071: `extract_parameter_names` mangles keyword defaults and defaults containing commas
- **Location**: `warnings/unknown_parameter_name/messages_builder.rb:129-142`
- **Category**: wrong-behavior · **Confidence**: high (reproduced)

`"mode: :fast, list = [1, 2], name"` → `["mode fast", "list", "2]", "name"]` — garbage entries
pollute the DidYouMean dictionary.

### BUG-072: One-line warning parsers: paths containing `line ` yield line 0; ` in file ` garbles messages
- **Location**: `warnings/unknown_tag/parser.rb:15-17` (same regexes in unknown_directive, invalid_tag_format, invalid_directive_format); driven by `parsers/one_line_base.rb:18-23`
- **Category**: wrong-behavior · **Confidence**: high (reproduced)

`line: /line (\d*)/` matches the first "line " (e.g. in `/home/u/command line tools/a.rb`) with an
empty capture → line 0; greedy `message: /\[warn\]: (.*) in file/` truncates on paths containing
" in file ". Fix: `/near line (\d+)/` (as the two-line parsers do) + non-greedy capture.

### BUG-075: YARD logger level not restored on parse exception
- **Location**: `executor/in_process_registry.rb:35-62`
- **Category**: wrong-behavior · **Confidence**: medium (code-read)

`level = original_level` is not in an `ensure`; if `YARD.parse` raises, the process-global logger
stays silenced for the rest of the run.

### BUG-078: Invalid UTF-8 sources silently skipped per object
- **Location**: `executor/query_executor.rb` (broad `ArgumentError`/`StandardError` rescue)
- **Category**: false-negative (hidden) · **Confidence**: medium (verified no-crash)

No crash, but affected objects are silently skipped unless `DEBUG` is set — related to the rescue
design noted in BUG-002.

## 6. Execution pipeline (runner / executor / git / parsers / results)

Bugs already attributed to these files via other slices and independently re-confirmed by the
pipeline audit: BUG-002 (QueryExecutor NameError swallow), BUG-004 (Order zip misalignment),
BUG-014 (diff modes from subdirectory), BUG-026 (`start_with?` prefix), BUG-031
(UndocumentedBooleanMethods dead).

### BUG-079: IRB notifier shim breaks YARD's legacy lexer — docstrings silently destroyed, false positives
- **Location**: `lib/yard/lint/ext/irb_notifier_shim.rb:40-101`
- **Category**: false-positive / wrong-behavior · **Confidence**: high (reproduced)

On the exact environment the shim targets (Ruby 3.5+, where `require 'irb/notifier'` fails), the
shim pushes `'irb/notifier.rb'` into `$LOADED_FEATURES`, suppressing YARD's vendored `slex.rb`'s
*own complete* LoadError fallback. The shim's `NoOpNotifier` lacks `exec_if`, which
`SLex::Node#match_io` calls on a common backtracking path. Reproduced: lexing
`@overload fetch(key, default=build_it)` raises `NoMethodError: undefined method 'exec_if'`; inside
the pipeline the handler exception is suppressed by the registry's log level, the docstring's tags
are silently dropped, and a fully documented method gains a **`Documentation/UndocumentedObjects`
false positive**. Secondary: if the `$LOADED_FEATURES` suppression doesn't apply, slex's fallback
defines `module Notifier`, colliding with the shim's `class Notifier` → `TypeError`.

### BUG-080: Diff modes silently skip filenames with non-ASCII characters
- **Location**: `lib/yard/lint/git.rb:104`
- **Category**: false-negative · **Confidence**: high (reproduced)

With git's default `core.quotepath=true`, non-ASCII paths are emitted C-quoted
(`"sub/lib/\305\274...rb"`); the line ends with `"`, so `end_with?('.rb')` is false and the file is
dropped. Verified: `żół.rb` missing from `changed_files`. Fix: `-z` output or `-c core.quotepath=off`.

### BUG-081: `--changed` (uncommitted) mode ignores untracked files
- **Location**: `lib/yard/lint/git.rb:71-82`
- **Category**: false-negative · **Confidence**: high (verified)

`git diff --name-only HEAD` lists only tracked changes; a brand-new, unstaged `.rb` file is never
linted, although the mode is documented as "all changes in working directory".

### BUG-082: Files with syntax errors are skipped with no offense and no message
- **Location**: `lib/yard/lint/executor/in_process_registry.rb:34-36`
- **Category**: wrong-behavior / false-negative · **Confidence**: high (reproduced)

`YARD::Logger.instance.level = 4` suppresses `[error]` messages too (syntax errors, handler
exceptions). A file that fails to parse contributes nothing — no offense, no diagnostics — and the
run can exit 0. The YARD CLI would at least print the syntax error. (Restore-on-exception variant
of this is BUG-075.)

### BUG-083: `StatsCalculator` silently reports 100% coverage when the `yard` subprocess fails
- **Location**: `lib/yard/lint/stats_calculator.rb:35-37, 53-58`
- **Category**: wrong-behavior / false-negative · **Confidence**: high (reproduced)

`return '' unless status.exitstatus.zero?` turns any failure (yard binary missing, query error)
into empty output → `default_stats` → `coverage: 100.0`, so a configured `MinCoverage` gate
**passes**. This is the one component that still shells out. Also `status.exitstatus` is `nil` if
the process dies on a signal → `NoMethodError` crash.

### BUG-084: Composite child results dropped when the parent validator is disabled
- **Location**: `lib/yard/lint/result_builder.rb:42-49`, `lib/yard/lint/runner.rb:164-167`
- **Category**: wrong-behavior / false-negative · **Confidence**: medium (structural; currently masked by BUG-031)

`composite_child?` unconditionally returns true for `Documentation/UndocumentedBooleanMethods`, so
its offenses surface only via the parent composite. Disabling `Documentation/UndocumentedObjects`
while keeping the child enabled still runs the child but silently discards its offenses.

### BUG-085: `PathGrouper` emits unusable `./**/*` pattern and uses inconsistent coverage math
- **Location**: `lib/yard/lint/path_grouper.rb:34-65`
- **Category**: wrong-behavior · **Confidence**: high for the `.` case (reproduced)

(a) For ≥15 offending files at the project root, grouping produces `"./**/*"` —
`File.fnmatch('./**/*', 'foo.rb', FNM_PATHNAME)` is false, so the generated todo file fails to
exclude those offenses and yard-lint keeps failing right after `--generate-todo`. (b) Coverage
compares *direct* files in a dir against a *recursive* glob and counts nonexistent input paths
(coverage 20/8 = 2.5 in repro), while the emitted `dir/**/*` pattern recursively excludes
subdirectory files that had no offenses.

### BUG-086: Cross-thread warning attribution via process-global YARD logger
- **Location**: `lib/yard/lint/executor/in_process_registry.rb` (`capture_warnings`)
- **Category**: wrong-behavior · **Confidence**: low (theoretical)

The singleton `warn` is restored correctly via `ensure`, but `YARD::Logger.instance` is
process-wide: two `Runner`s in different threads would cross-attribute captured warnings — the
instance-level mutex doesn't protect this. Single-runner usage is fine.

---

## Cross-references for fixing in batches

Several bugs share one root cause and are best fixed together:

- **`||`-based config fallback** → BUG-001 (fix once in `Validators::Base`).
- **`all_typed_tags` not used** → BUG-005 (four validators, one helper).
- **OptionTag `pair` accessors** → BUG-006 (four validators).
- **Offense dedup** → BUG-007 (one fix in the result pipeline).
- **Docstring line attribution** → BUG-008 (use `docstring.line_range` + offset consistently).
- **Template/code default drift** → BUG-009 (regenerate template from `Config.defaults`, add a test).
- **Location regex `[#.]`** → BUG-003 + BUG-004 (fix regex, then the zip becomes safe; consider
  keying by location instead of index regardless).
- **Path/base-dir semantics** → BUG-012, BUG-013, BUG-014, BUG-026 (define one canonical base:
  config-file dir for patterns, repo root for git paths).
- **Git file-listing** → BUG-014, BUG-080, BUG-081 (use `-z` + repo-root expansion + include
  untracked via `--others --exclude-standard` in one pass over `git.rb`).
- **Silenced YARD logger** → BUG-075, BUG-082 (capture `[error]`s instead of muting; restore level
  in `ensure`).
- **Psych/CLI error handling** → BUG-015, BUG-017, BUG-029 (one top-level rescue + `aliases: true`).

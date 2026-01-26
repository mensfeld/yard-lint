# YARD-Lint Future Enhancements

This document outlines potential features and improvements, **organized by ROI (Return on Investment)** to prioritize high-impact, low-effort features first.

## Comparison with rubocop-yard

### Current State

**rubocop-yard: 6 cops**
1. YARD/TagTypeSyntax - Detects type syntax errors
2. YARD/TagTypePosition - Validates type position in tags
3. YARD/CollectionStyle - Enforces collection notation style (long vs short)
4. YARD/CollectionType - Flags incorrect Hash/Array syntax
5. YARD/MismatchName - Validates @param/@option against method signatures
6. YARD/MeaninglessTag - Prevents @param/@option on non-methods

**YARD-Lint: 21 validators**

Documentation (5):
- Documentation/UndocumentedObjects
- Documentation/UndocumentedMethodArguments
- Documentation/UndocumentedBooleanMethods
- Documentation/UndocumentedOptions
- Documentation/MarkdownSyntax

Tags (10):
- Tags/Order
- Tags/InvalidTypes
- Tags/TypeSyntax
- Tags/MeaninglessTag (same as rubocop-yard)
- Tags/CollectionType (same as rubocop-yard, supports both long and short styles)
- Tags/TagTypePosition (same as rubocop-yard)
- Tags/ApiTags
- Tags/OptionTags
- Tags/ExampleSyntax
- Tags/RedundantParamDescription

Warnings (6):
- Warnings/UnknownTag
- Warnings/UnknownDirective
- Warnings/InvalidDirectiveFormat
- Warnings/InvalidTagFormat
- Warnings/DuplicatedParameterName
- Warnings/UnknownParameterName (similar to rubocop-yard's MismatchName)

Semantic (1):
- Semantic/AbstractMethods

### Key Differentiators

**YARD-Lint Advantages:**
- 3.5x more validators (21 vs 6)
- Undocumented code detection (rubocop-yard doesn't detect missing docs)
- Standalone tool (doesn't require RuboCop)
- YARD warnings integration
- API tag enforcement
- Abstract method validation
- Works on large codebases (ARG_MAX fix)
- Diff mode support (--diff, --staged, --changed)
- Documentation coverage metrics (--stats, --min-coverage)
- Markdown syntax validation
- Example code syntax validation
- Redundant description detection
- Collection style options (long vs short, same as rubocop-yard)

**rubocop-yard Advantages:**
- RuboCop integration (familiar workflow)
- Mature ecosystem

---

## ✅ Already Implemented Features

The following features from the original roadmap have been successfully implemented:

1. **✅ Diff Mode** - `--diff`, `--staged`, `--changed` flags for incremental linting
2. **✅ Documentation Coverage Metrics** - `--stats` and `--min-coverage` flags
3. **✅ Undocumented Options Validator** - `Documentation/UndocumentedOptions` validator
4. **✅ Markdown Syntax Errors** - `Documentation/MarkdownSyntax` validator
5. **✅ Example Syntax Validation** - `Tags/ExampleSyntax` validator
6. **✅ Redundant Parameter Descriptions** - `Tags/RedundantParamDescription` validator
7. **✅ Short Collection Style Support** - `EnforcedStyle` option in `Tags/CollectionType` validator (supports both `long` and `short` styles)

---

## 🚀 TIER 1: Quick Wins (Low Effort, High Impact)

Implement these first for maximum ROI.

### 1. CI/CD Integration Templates ⭐⭐⭐
**Impact:** HIGH
**Effort:** LOW (mostly documentation)
**ROI:** 🔥 VERY HIGH

Make integration trivial with ready-made templates.

**Deliverables:**
- GitHub Actions workflow template
- GitLab CI template
- review-dog integration (inline PR comments)
- Danger integration
- CircleCI config example
- Pre-commit hook example

**Example GitHub Action:**
```yaml
# .github/workflows/yard-lint.yml
name: YARD Documentation Lint

on:
  pull_request:
    paths:
      - '**/*.rb'

jobs:
  yard-lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true

      - name: Run YARD-Lint
        run: |
          bundle exec yard-lint --diff origin/${{ github.base_ref }} \
                                --format json \
                                --fail-on-severity warning
```

---

### 2. Summary Quality Validator ⭐⭐⭐
**Impact:** HIGH - Ensures doc quality, not just presence
**Effort:** LOW-MEDIUM
**ROI:** 🔥 VERY HIGH

**What to check:**
- Summary length constraints (e.g., max 80 characters for first line)
- Summary delimiter format (should end with period)
- Single-line requirement for summaries
- Presence of descriptions beyond just tags

**Implementation as new validator:**
```yaml
Documentation/SummaryQuality:
  Description: 'Validates quality of method/class summaries'
  Enabled: true
  Severity: convention
  MaxSummaryLength: 80
  RequirePeriod: true
  RequireSingleLine: true
```

**Example violations:**
```ruby
# Bad: Too long
# This is a really really really really really really really really long summary that exceeds the character limit

# Bad: Missing period
# Process the data

# Bad: Multi-line summary
# Process the data
# using the given options
```

---

## 💎 TIER 2: Major Differentiators (Medium Effort, Huge Impact)

### 3. Auto-Correction / Auto-Fix ⭐⭐⭐
**Impact:** HUGE differentiator
**Effort:** MEDIUM
**ROI:** 💎 EXCELLENT

rubocop-yard has NO auto-correction capability. Adding `--fix` flag would be a massive advantage.

**Implementation:**
```bash
yard-lint --fix lib/
```

**Auto-fixable validators:**
- Tags/CollectionType: `Hash<K,V>` → `Hash{K => V}`
- Tags/TagTypePosition: `@param [Type] name` → `@param name [Type]`
- Tags/Order: Reorder tags to match EnforcedOrder
- Documentation/UndocumentedBooleanMethods: Add `@return [Boolean]` stub
- Documentation/UndocumentedMethodArguments: Add missing `@param` stubs

**Why it matters:** Developers love tools that fix things, not just complain about them.

---

### 4. Generate Documentation Stubs ⭐⭐⭐
**Impact:** HUGE for adoption
**Effort:** MEDIUM
**ROI:** 💎 EXCELLENT

Instead of just complaining about missing docs, generate scaffolding automatically.

**Usage:**
```bash
yard-lint --generate-docs lib/my_file.rb
```

**Example:**
```ruby
# Before
def process(name, age)
  # ...
end

# After (with --generate-docs)
# Process data
# @param name [String]
# @param age [Integer]
# @return [void]
def process(name, age)
  # ...
end
```

**Smart generation:**
- Infer types from parameter names (e.g., `user_id` → `[Integer]`)
- Detect return types from code analysis
- Generate placeholder descriptions that developers fill in
- Respect existing partial documentation

---

### 5. HTML/Web Report Output ⭐⭐
**Impact:** MEDIUM-HIGH
**Effort:** MEDIUM
**ROI:** 💎 GOOD

JSON and text are good, but HTML is more accessible for sharing with teams.

**Features:**
- Interactive report with sortable/filterable offense table
- Per-file drill-down
- Severity distribution charts
- Coverage metrics
- Trends over time (if storing historical data)
- Dark mode support

**Usage:**
```bash
yard-lint --format html --output-file report.html lib/
```

---

## ⚡ TIER 3: Strategic Plays (High Effort, High Impact)

### 6. IDE Integration ⭐⭐⭐
**Impact:** HIGH
**Effort:** HIGH
**ROI:** ⚡ STRATEGIC

Real-time feedback in editors.

**Deliverables:**
- VS Code extension with real-time linting
- RubyMine/IntelliJ IDEA plugin
- LSP (Language Server Protocol) support
- Inline warnings as you type
- Quick-fix actions for auto-correctable issues

---

### 7. RuboCop Integration (Plugin) ⭐⭐
**Impact:** MEDIUM-HIGH
**Effort:** MEDIUM
**ROI:** ⚡ STRATEGIC

Create `rubocop-yard-lint` plugin that wraps YARD-Lint validators as RuboCop cops.

**Benefits:**
- Captures RuboCop user base
- Best of both worlds (standalone CLI + RuboCop integration)
- Familiar workflow for RuboCop users

**Implementation:**
```ruby
# lib/rubocop/cop/yard_lint/undocumented_objects.rb
module RuboCop
  module Cop
    module YardLint
      class UndocumentedObjects < Base
        def on_class(node)
          # Delegate to YARD-Lint validator
        end
      end
    end
  end
end
```

---

### 8. Performance Optimizations ⭐⭐
**Impact:** MEDIUM
**Effort:** MEDIUM
**ROI:** ⚡ GOOD

**Features:**
- `--profile` flag showing which validators are slowest
- `--cache` flag to cache YARD database between runs
- Parallel processing for multiple files
- Incremental analysis (only re-analyze changed files)

**Usage:**
```bash
yard-lint --profile lib/
# Output:
# Validator                                Time    %
# Documentation/UndocumentedObjects       2.3s   45%
# Tags/InvalidTypes                       1.2s   23%
# ...

yard-lint --cache lib/
# Second run is 5x faster
```

---

## 🎯 TIER 4: Nice-to-Have (Lower Priority)

### 9. Watch Mode ⭐
**Impact:** LOW-MEDIUM
**Effort:** LOW
**ROI:** 🎯 MODERATE

Continuous linting during development.

**Usage:**
```bash
yard-lint --watch lib/
# Reruns on file changes
# Great for TDD-style documentation development
```

---

### 10. Severity Customization Per Path ⭐
**Impact:** MEDIUM
**Effort:** LOW
**ROI:** 🎯 GOOD

Different rules for different parts of the codebase.

**Configuration:**
```yaml
Documentation/UndocumentedObjects:
  Enabled: true
  Severity: warning

  # Per-path severity overrides
  PathSeverity:
    'lib/internal/**/*': convention  # Less strict for internal code
    'lib/api/**/*': error             # Strict for public API
    'lib/experimental/**/*': never    # Ignore experimental code
```

---

## 🏆 Implementation Roadmap (Prioritized by ROI)

### Phase 1: Quick Wins (Implement First - 1 week)
These deliver maximum value with minimal effort:

1. **CI/CD Integration Templates** - GitHub Actions, GitLab CI examples
2. **Summary Quality Validator** - Enforce doc quality standards

**Estimated effort:** 1 week
**Impact:** Immediate adoption boost, CI/CD integration

---

### Phase 2: Major Differentiators (Next Priority - 2-4 weeks)
These create significant gaps vs. competitors:

3. **Auto-Correction** - `--fix` flag for fixable validators
4. **Generate Documentation Stubs** - `--generate-docs` scaffolding
5. **HTML/Web Report Output** - Interactive reports

**Estimated effort:** 2-4 weeks
**Impact:** Massive value-add that rubocop-yard doesn't have

---

### Phase 3: Strategic Plays (Long-term - 1-3 months)
High effort but strategically important:

6. **IDE Integration** - VS Code extension, LSP server
7. **RuboCop Integration Plugin** - `rubocop-yard-lint` gem
8. **Performance Optimizations** - Caching, profiling, parallelization

**Estimated effort:** 1-3 months
**Impact:** Market expansion, ecosystem integration

---

### Phase 4: Polish (As needed)
Lower priority enhancements:

9. **Watch Mode** - Continuous linting during development
10. **Severity Customization Per Path** - Fine-grained control

---

## 🎯 Top 3 Recommendations for Maximum ROI

If implementing only 3 features next, prioritize these in order:

1. **Auto-Correction** (💎 EXCELLENT ROI)
   - Makes YARD-Lint drastically more useful than rubocop-yard
   - Developers love tools that fix, not just complain
   - Reduces friction significantly

2. **CI/CD Integration Templates** (🔥 VERY HIGH ROI)
   - Mostly documentation work
   - Removes barriers to adoption
   - Makes integration trivial

3. **Generate Documentation Stubs** (💎 EXCELLENT ROI)
   - Helps teams adopt YARD-Lint on existing codebases
   - Scaffolds documentation instead of just complaining
   - Reduces developer friction

**These three features would create a massive gap between YARD-Lint and rubocop-yard while requiring reasonable development effort.**

---

## 📋 Additional Validator Ideas

### MEDIUM PRIORITY (Consider for Phase 2)

**11. Link::To::Class Detection** ⭐⭐
- **Impact:** MEDIUM
- **Effort:** MEDIUM
- **ROI:** 💎 GOOD
- **What:** Detect `Link::To::Class` that should be `{Link::To::Class}`
- **Value:** Improves documentation cross-references
- **Challenge:** Distinguishing actual links from code examples

---

### LOW PRIORITY (Phase 4 or Later)

**12. Unnecessary Return Docs for Predicates** ⭐
- **What:** Flag `@return [Boolean]` on `foo?` methods (YARD infers this)
- **Value:** LOW - Doesn't break anything, just redundant
- **Effort:** LOW

**13. Spellchecking** ⭐
- **What:** Check spelling in documentation text
- **Value:** MEDIUM for user-facing gems, LOW otherwise
- **Effort:** HIGH
- **Challenge:** Technical terms, code references, false positives

**14. HTML Tags vs @example** ⭐
- **What:** Detect HTML `<code>` tags that should be `@example`
- **Value:** LOW - Mostly style preference
- **Effort:** LOW

---

## 🔍 Insights from Yardstick Tool

From analyzing [yardstick](https://github.com/dkubb/yardstick) - a YARD documentation coverage tool by Dan Kubb.

### Already Covered by YARD-Lint ✅

1. **API tags presence** → `Tags/ApiTags` validator
2. **Undocumented methods** → `Documentation/UndocumentedObjects`
3. **Return type documentation** → `Documentation/UndocumentedMethodArguments`
4. **Protected/private method tagging** → Can be extended in `Tags/ApiTags`

### Key Takeaway from Yardstick

Yardstick's strength is **coverage measurement and threshold enforcement**. Adding `--min-coverage` and `--stats` (already in Phase 1) covers this gap and complements YARD-Lint's offense-based approach.

**Note:** Summary quality checks (already added as feature #5 in Phase 1) enforce **documentation quality**, not just presence - filling a gap that neither YARD-Lint nor rubocop-yard currently address.

---

## 💡 Final Summary

### Current State
- **YARD-Lint:** 21 validators (3.5x more than rubocop-yard)
- **rubocop-yard:** 6 cops, no auto-correction, RuboCop dependency

### Competitive Advantages (Already Implemented) ✅
✅ 3.5x more validators (21 vs 6)
✅ Standalone tool
✅ YARD warnings integration
✅ Works on large codebases (ARG_MAX fix)
✅ Undocumented code detection
✅ API tag enforcement
✅ Abstract method validation
✅ Diff mode support (--diff, --staged, --changed)
✅ Documentation coverage metrics (--stats, --min-coverage)
✅ Markdown syntax validation
✅ Example code syntax validation
✅ Redundant description detection
✅ Options hash documentation validation

### Next Steps for Maximum Impact

**Implement Phase 1 first (1 week):**
1. CI/CD Integration Templates
2. Summary Quality Validator

**These 2 features will:**
- Make CI/CD integration trivial
- Add quality enforcement (not just presence)

**Total estimated effort:** 1 week for high ROI boost

---

## 📝 Implementation Notes

### Bash Dependency Consideration

Current implementation uses bash-specific features (cat, xargs, pipes).

**Current status:**
- ✅ Unix/Linux/macOS: Works perfectly
- ❌ Windows (cmd.exe): Won't work
- ✅ Windows (WSL/Git Bash/Cygwin): Will work

**Recommendation:** Document Unix requirement in README. Most Ruby developers have Unix-like shells available.

---

## 📄 Changelog Integration

When implementing features, update CHANGELOG.md:

```markdown
## Unreleased
- **[Feature]** Add CI/CD integration templates (GitHub Actions, GitLab CI)
- **[Feature]** Add Documentation/SummaryQuality validator
- **[Feature]** Add auto-correction support (`--fix` flag)
```

---

## 💭 Additional Ideas (Unorganized)

These ideas need further evaluation and organization:

- Allow for parallel running of specs by having the yard cache per project (if not already like this)
- Detect pointless comments (e.g., `@param user [User] The user` - description adds no value beyond param name)
  - Note: This is partially addressed by `Tags/RedundantParamDescription` validator

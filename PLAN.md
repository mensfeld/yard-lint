# Implementation Plan: RuboCop/StandardRB Code Example Linting

## Overview

Implement `Tags/ExampleStyle` validator to lint code examples in `@example` tags using RuboCop or StandardRB. This ensures code examples follow the same style guidelines as the project codebase, maintaining consistency and providing better examples for both humans and AI assistants.

**Issue:** #74 - "allow linting code examples with standardrb/rubocop"

## Scope Assessment

✅ **Matches gem scope** - This feature fits perfectly within yard-lint's mission:
- Already validates @example syntax via `Tags/ExampleSyntax` validator
- Extends validation from syntax to style consistency
- Maintains documentation quality (yard-lint's core purpose)
- Follows established validator pattern

## Design Decisions

### 1. Validator Type: New `Tags/ExampleStyle` Validator
Create a separate validator from `Tags/ExampleSyntax` for:
- **Separation of concerns**: Syntax (correctness) vs style (conventions)
- **Independent configuration**: Users can enable syntax checking without style checking
- **Different severity**: Style = convention, Syntax = error
- **Clear responsibilities**: Each validator has one job

### 2. Default State: Opt-in (Disabled by Default)
**Rationale:**
- Requires external dependency (RuboCop or StandardRB gem)
- Won't break existing workflows
- Users consciously choose to enable style validation
- Follows pattern of other opt-in validators (`Tags/ApiTags`, `Documentation/MissingReturn`)

### 3. Severity: Convention
Style issues are cosmetic, not functional problems. Using 'convention' severity:
- Aligns with RuboCop's classification of style cops
- Won't fail CI by default (unless FailOnSeverity: convention)
- Users can override to 'warning' or 'error' if needed

### 4. Linter Detection: Pluggable with Smart Auto-Detection
Support mixed environments where projects may use RuboCop, StandardRB, or both across different contexts.

**Configuration options:**
```yaml
Tags/ExampleStyle:
  Linter: auto  # Options: 'auto', 'rubocop', 'standard', 'none'
```

**Auto-detection logic:**
1. Check for `.standard.yml` config file OR `standard` in Gemfile → use StandardRB
2. Check for `.rubocop.yml` config file OR `rubocop` in Gemfile → use RuboCop
3. If both present, prefer StandardRB (intentional opinionated choice over RuboCop)
4. If neither available, gracefully disable with debug warning

**Explicit configuration:**
- `Linter: rubocop` - Force RuboCop even if StandardRB available
- `Linter: standard` - Force StandardRB even if RuboCop available
- `Linter: none` - Explicitly disable linting

### 5. Cop Filtering: Disable Snippet-Irrelevant Cops
Default exclusions for cops that don't make sense for small code examples:
- `Style/FrozenStringLiteralComment` - Not needed in snippets
- `Layout/TrailingWhitespace` - YARD comment formatting artifacts
- `Layout/EndOfLine` - Cross-platform documentation
- `Metrics/MethodLength` - Examples are often long for illustration
- `Metrics/AbcSize` - Complexity metrics not relevant for examples
- `Metrics/CyclomaticComplexity` - Ditto

Users can customize via `DisabledCops` config option.

### 6. Skipping "Bad Code" Examples
Support multiple ways to skip linting for intentional bad examples:

**Pattern-based skip:**
```ruby
# @example Bad code (skip-lint)
#   user = User.new("wrong")
```

**Inline RuboCop directives (native support):**
```ruby
# @example
#   # rubocop:disable all
#   user = User.new("wrong")
#   # rubocop:enable all
```

**Config patterns:**
```yaml
Tags/ExampleStyle:
  SkipPatterns:
    - '/skip-lint/i'
    - '/bad code/i'
    - '/anti-pattern/i'
```

## Implementation Structure

### Files to Create

```
lib/yard/lint/validators/tags/example_style.rb           # Module registration
lib/yard/lint/validators/tags/example_style/
├── validator.rb                                          # Main validator logic
├── config.rb                                             # Configuration defaults
├── parser.rb                                             # Parse validator output
├── result.rb                                             # Result object
├── messages_builder.rb                                   # Format messages
├── linter_detector.rb                                    # Detect RuboCop/StandardRB
└── rubocop_runner.rb                                     # Run RuboCop on snippets
```

### Critical Files for Reference

- `/lib/yard/lint/validators/tags/example_syntax/validator.rb` - Pattern for iterating @example tags, code extraction/cleaning
- `/lib/yard/lint/validators/tags/example_syntax/parser.rb` - Output parsing pattern
- `/lib/yard/lint/validators/tags/example_syntax/result.rb` - Result building pattern
- `/lib/yard/lint/validators/tags/example_syntax/messages_builder.rb` - Message formatting pattern
- `/lib/yard/lint/validators/tags/example_syntax/config.rb` - Config structure pattern
- `/lib/yard/lint/validators/base.rb` - Base class with `in_process_query` signature

## Implementation Details

### 1. Module Registration File

**File:** `lib/yard/lint/validators/tags/example_style.rb`

```ruby
# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        # ExampleStyle validator
        #
        # Validates code style in `@example` tags using RuboCop or StandardRB.
        # This validator ensures that code examples follow the same style guidelines
        # as the project codebase for consistency.
        #
        # ## Requirements
        #
        # - RuboCop or StandardRB gem must be installed
        # - Validator auto-detects which linter to use based on project setup
        #
        # ## Configuration
        #
        # Basic usage:
        #
        #     Tags/ExampleStyle:
        #       Enabled: true
        #
        # Advanced configuration:
        #
        #     Tags/ExampleStyle:
        #       Enabled: true
        #       Linter: auto  # 'auto', 'rubocop', 'standard', or 'none'
        #       SkipPatterns:
        #         - '/skip-lint/i'
        #         - '/bad code/i'
        #       DisabledCops:
        #         - 'Metrics/MethodLength'
        #
        # ## Skipping Examples
        #
        # Skip linting for specific examples (negative examples):
        #
        #     # @example Bad code (skip-lint)
        #     #   user = User.new("invalid")
        #
        # Or use inline RuboCop directives:
        #
        #     # @example
        #     #   # rubocop:disable all
        #     #   user = User.new("invalid")
        #     #   # rubocop:enable all
        module ExampleStyle
          autoload :Validator, 'yard/lint/validators/tags/example_style/validator'
          autoload :Config, 'yard/lint/validators/tags/example_style/config'
          autoload :Parser, 'yard/lint/validators/tags/example_style/parser'
          autoload :Result, 'yard/lint/validators/tags/example_style/result'
          autoload :MessagesBuilder, 'yard/lint/validators/tags/example_style/messages_builder'
          autoload :LinterDetector, 'yard/lint/validators/tags/example_style/linter_detector'
          autoload :RubocopRunner, 'yard/lint/validators/tags/example_style/rubocop_runner'
        end
      end
    end
  end
end
```

### 2. Config Class

**File:** `lib/yard/lint/validators/tags/example_style/config.rb`

```ruby
# frozen_string_literal: true

module Yard
  module Lint
    module Validators
      module Tags
        module ExampleStyle
          # Configuration for ExampleStyle validator
          class Config < ::Yard::Lint::Validators::Config
            self.id = :example_style
            self.defaults = {
              'Enabled' => false,  # Opt-in validator
              'Severity' => 'convention',
              'Linter' => 'auto',  # 'auto', 'rubocop', 'standard', or 'none'
              'RespectProjectConfig' => true,
              'CustomConfigPath' => nil,
              'SkipPatterns' => [],
              'DisabledCops' => [
                # File-level cops that don't make sense for code snippets
                'Style/FrozenStringLiteralComment',
                'Layout/TrailingWhitespace',
                'Layout/EndOfLine',
                'Metrics/MethodLength',
                'Metrics/AbcSize',
                'Metrics/CyclomaticComplexity',
                'Metrics/PerceivedComplexity'
              ]
            }.freeze
          end
        end
      end
    end
  end
end
```

### 3. Linter Detector

**File:** `lib/yard/lint/validators/tags/example_style/linter_detector.rb`

**Purpose:** Smart detection of available linters with pluggable configuration

**Key logic:**
- Check for gem availability using `require`
- Check for config files (`.standard.yml`, `.rubocop.yml`)
- Check Gemfile for explicit gem declarations
- Return `:standard`, `:rubocop`, or `:none`

**Detection priority (when both available):**
1. StandardRB if `.standard.yml` exists
2. RuboCop if `.rubocop.yml` exists
3. StandardRB if `standard` in Gemfile
4. RuboCop if `rubocop` in Gemfile
5. None if neither

### 4. RuboCop Runner

**File:** `lib/yard/lint/validators/tags/example_style/rubocop_runner.rb`

**Purpose:** Execute RuboCop/StandardRB on code snippets and parse results

**Key responsibilities:**
- Skip examples matching SkipPatterns
- Clean code using same logic as ExampleSyntax (remove `# =>` output indicators)
- Run RuboCop via stdin to avoid file I/O
- Pass disabled cops to RuboCop command
- Parse JSON output into offense hashes
- Handle errors gracefully (missing gem, invalid config, etc.)

**Command construction:**
```bash
# For RuboCop
rubocop --format json --stdin example.rb --except Cop1 --except Cop2 < code

# For StandardRB
standardrb --format json --stdin example.rb < code
```

**Note:** StandardRB doesn't support `--except` for individual cops. Users must disable cops via `.standard.yml` config if needed.

### 5. Validator Implementation

**File:** `lib/yard/lint/validators/tags/example_style/validator.rb`

**Pattern:** Mirror `ExampleSyntax::Validator` structure

**Key logic:**
1. Declare `in_process visibility: :all` (check all objects including private)
2. Implement `in_process_query(object, collector)`
3. Check for `@example` tags on object
4. Iterate over example tags
5. For each example:
   - Extract code from `example.text`
   - Get example name from `example.name` or generate default
   - Check skip patterns
   - Run linter via RubocopRunner
   - For each offense, output to collector:
     ```
     file.rb:10: ClassName#method_name
     style_offense
     Example name
     Cop name
     Offense message
     ```

**Error handling:**
- Detect linter type (via LinterDetector)
- If no linter available, silently skip (graceful degradation)
- Catch RuboCop errors and log in debug mode only

### 6. Parser Implementation

**File:** `lib/yard/lint/validators/tags/example_style/parser.rb`

**Pattern:** Mirror `ExampleSyntax::Parser` structure

**Input format:**
```
lib/user.rb:45: User#initialize
style_offense
Example 1
Style/StringLiterals
Prefer single-quoted strings when you don't need interpolation
lib/user.rb:45: User#initialize
style_offense
Example 1
Layout/SpaceInsideHashLiteralBraces
Space inside { missing
```

**Output format:**
```ruby
[
  {
    name: 'ExampleStyle',
    object_name: 'User#initialize',
    example_name: 'Example 1',
    cop_name: 'Style/StringLiterals',
    message: 'Prefer single-quoted strings...',
    location: 'lib/user.rb',
    line: 45
  },
  # ...
]
```

### 7. Result Implementation

**File:** `lib/yard/lint/validators/tags/example_style/result.rb`

**Pattern:** Mirror `ExampleSyntax::Result` structure

```ruby
class Result < Results::Base
  self.default_severity = 'convention'
  self.offense_type = 'line'
  self.offense_name = 'ExampleStyleOffense'

  def build_message(offense)
    MessagesBuilder.call(offense)
  end

  private

  def build_offenses
    @parsed_data.map do |offense_data|
      {
        severity: configured_severity,
        type: self.class.offense_type,
        name: offense_data[:name] || self.class.offense_name,
        message: build_message(offense_data),
        location: offense_data[:location],
        location_line: offense_data[:line]
      }
    end
  end
end
```

### 8. Messages Builder

**File:** `lib/yard/lint/validators/tags/example_style/messages_builder.rb`

**Pattern:** Mirror `ExampleSyntax::MessagesBuilder` structure

**Message format:**
```
Object `User#initialize` has style offense in @example 'Usage': Style/StringLiterals: Prefer single-quoted strings
```

## Configuration Example

Add to `.yard-lint.yml`:

```yaml
Tags/ExampleStyle:
  Description: 'Validates code style in @example tags using RuboCop/StandardRB'
  Enabled: true
  Severity: convention
  Linter: auto  # 'auto', 'rubocop', 'standard', or 'none'
  RespectProjectConfig: true  # Use project's .rubocop.yml or .standard.yml
  CustomConfigPath: null      # Optional: custom RuboCop config for examples only
  SkipPatterns: []            # Regex patterns to skip examples (e.g., '/skip-lint/i')
  DisabledCops:               # Cops disabled by default for snippets
    - 'Style/FrozenStringLiteralComment'
    - 'Layout/TrailingWhitespace'
    - 'Layout/EndOfLine'
    - 'Metrics/MethodLength'
    - 'Metrics/AbcSize'
    - 'Metrics/CyclomaticComplexity'
    - 'Metrics/PerceivedComplexity'
```

## Edge Cases & Error Handling

### 1. No Linter Available
- **Scenario:** Validator enabled but neither RuboCop nor StandardRB installed
- **Handling:** Log debug warning, return no offenses, don't fail the run
- **Message:** `[YARD-Lint] ExampleStyle validator enabled but no linter (RuboCop/StandardRB) found. Skipping.`

### 2. Invalid RuboCop Configuration
- **Scenario:** Project's `.rubocop.yml` has syntax errors
- **Handling:** Catch and report as yard-lint offense
- **Message:** `ExampleStyle validation failed: Invalid RuboCop configuration: [error details]`

### 3. Code Snippets Not Valid Standalone Ruby
- **Scenario:** Examples showing partial syntax (e.g., `user.name`)
- **Handling:** RuboCop will fail on invalid Ruby; catch and skip silently
- **Note:** ExampleSyntax already validates syntax, so most invalid snippets are caught there

### 4. Examples with Inline RuboCop Directives
- **Scenario:** Examples contain `# rubocop:disable` comments
- **Handling:** RuboCop naturally respects these; no special handling needed

### 5. Empty or Whitespace-Only Examples
- **Scenario:** `@example` tag with no code or just whitespace
- **Handling:** Skip after code cleaning (cleaned_code.empty? check)

### 6. RuboCop Version Compatibility
- **Scenario:** Different RuboCop versions have different JSON output formats
- **Handling:** Test with RuboCop 1.x (current stable), document minimum version
- **Mitigation:** Wrap JSON parsing in rescue block

### 7. StandardRB Cop Exclusions
- **Scenario:** StandardRB doesn't support `--except` flag for individual cops
- **Handling:** Document that DisabledCops only works with RuboCop linter
- **Alternative:** Users can configure exclusions in `.standard.yml` file

### 8. Multiple Offenses per Example
- **Scenario:** Single example has multiple RuboCop violations
- **Handling:** Report each offense separately (mirrors RuboCop behavior)

## Testing Strategy

### Unit Tests

**File:** `spec/yard/lint/validators/tags/example_style/linter_detector_spec.rb`
- Test StandardRB detection when gem available + config file present
- Test StandardRB detection when gem available + in Gemfile
- Test RuboCop detection when gem available + config file present
- Test RuboCop detection when gem available + in Gemfile
- Test priority when both available (StandardRB preferred)
- Test fallback to none when neither available
- Test gem_installed? method with missing gems

**File:** `spec/yard/lint/validators/tags/example_style/rubocop_runner_spec.rb`
- Test running RuboCop on clean code (no offenses)
- Test running RuboCop on code with style violations
- Test skip patterns matching
- Test code cleaning (removing `# =>` output indicators)
- Test disabled cops passed to RuboCop
- Test StandardRB vs RuboCop command construction
- Test JSON parsing of RuboCop output
- Test error handling (missing gem, invalid JSON, RuboCop failure)

**File:** `spec/yard/lint/validators/tags/example_style/parser_spec.rb`
- Test parsing validator output with single offense
- Test parsing multiple offenses
- Test handling empty output
- Test handling malformed output (skip gracefully)

**File:** `spec/yard/lint/validators/tags/example_style/messages_builder_spec.rb`
- Test message formatting with all offense data

**File:** `spec/yard/lint/validators/tags/example_style/result_spec.rb`
- Test offense building
- Test severity configuration
- Test message building integration

**File:** `spec/yard/lint/validators/tags/example_style/validator_spec.rb`
- Test linter detection (auto mode)
- Test explicit linter configuration
- Test graceful handling when no linter available
- Test integration with RubocopRunner
- Test skip patterns applied correctly
- Test output format to collector

### Integration Tests

**File:** `spec/integrations/example_style_spec.rb`

Test complete end-to-end validation flows:

1. **Basic style offense detection:**
   ```ruby
   fixture = <<~RUBY
     class User
       # @example
       #   user = User.new("John", "Doe")
       def initialize(first, last)
       end
     end
   RUBY
   # Expect: Style/StringLiterals offense for double-quoted strings
   ```

2. **Skip patterns:**
   ```ruby
   fixture = <<~RUBY
     # @example Bad code (skip-lint)
     #   user = User.new("invalid")
   RUBY
   # Expect: No offenses
   ```

3. **Multiple examples per object:**
   ```ruby
   fixture = <<~RUBY
     class User
       # @example Good usage
       #   user = User.new('John')
       # @example Bad usage (skip-lint)
       #   user = User.new("John")
       def initialize(name)
       end
     end
   RUBY
   # Expect: No offenses (first is clean, second skipped)
   ```

4. **Inline RuboCop directives:**
   ```ruby
   fixture = <<~RUBY
     # @example
     #   # rubocop:disable Style/StringLiterals
     #   user = User.new("John")
     #   # rubocop:enable Style/StringLiterals
   RUBY
   # Expect: No offenses (disabled inline)
   ```

5. **Graceful degradation when RuboCop not available:**
   - Mock gem loading to raise LoadError
   - Expect: No offenses, validator skipped silently

6. **StandardRB vs RuboCop selection:**
   - Mock different project setups
   - Verify correct linter chosen

7. **Disabled cops configuration:**
   - Configure DisabledCops
   - Verify those cops don't report offenses

8. **Multiple offenses in single example:**
   ```ruby
   fixture = <<~RUBY
     # @example
     #   user = User.new( "John" , "Doe" )
   RUBY
   # Expect: Multiple offenses (StringLiterals, SpaceInsideParens, etc.)
   ```

## Documentation Updates

### README.md Changes

**Location:** Features section (after line 34)
Add:
```markdown
- **Example code style validation**: Validates code style in `@example` tags using RuboCop or StandardRB to ensure consistency with your codebase (opt-in)
```

**Location:** New section after "Adopting YARD-Lint on Existing Projects"
Add:
```markdown
### Validating Code Example Style

The `Tags/ExampleStyle` validator ensures code examples in `@example` tags follow your project's style guidelines using RuboCop or StandardRB.

**Requirements:**
- RuboCop or StandardRB gem must be installed in your project
- Validator auto-detects which linter to use based on your project setup

**Enable the validator:**

```yaml
# .yard-lint.yml
Tags/ExampleStyle:
  Enabled: true
```

The validator will automatically:
- Detect RuboCop or StandardRB from your project setup
- Use your project's `.rubocop.yml` or `.standard.yml` configuration
- Report style offenses in code examples

**Skipping specific examples:**

For examples intentionally showing bad code (anti-patterns, common mistakes):

```ruby
# @example Bad code (skip-lint)
#   user = User.new("invalid")
```

Or use inline RuboCop directives:

```ruby
# @example
#   # rubocop:disable Style/StringLiterals
#   user = User.new("invalid")
#   # rubocop:enable Style/StringLiterals
```

**Advanced configuration:**

```yaml
Tags/ExampleStyle:
  Enabled: true
  Linter: auto  # Options: 'auto', 'rubocop', 'standard', 'none'
  SkipPatterns:
    - '/skip-lint/i'
    - '/bad code/i'
    - '/anti-pattern/i'
  DisabledCops:  # Additional cops to disable beyond defaults
    - 'Style/SomeCustomCop'
```

**Note:** This validator is opt-in (disabled by default). Style violations have 'convention' severity by default and won't fail CI unless your `FailOnSeverity` is set to 'convention'.
```

### CHANGELOG.md

Add to unreleased section:
```markdown
## [Unreleased]

### Added
- New `Tags/ExampleStyle` validator for linting code examples with RuboCop/StandardRB (#74)
  - Auto-detects RuboCop or StandardRB from project setup (pluggable detection)
  - Respects project's `.rubocop.yml` or `.standard.yml` configuration
  - Supports skip patterns for intentional "bad code" examples
  - Opt-in validator (disabled by default, requires RuboCop or StandardRB gem)
  - Convention severity by default for style issues
  - Automatically disables file-level cops irrelevant to code snippets
```

### Default Config Template

**File:** `lib/yard/lint/templates/default_config.yml`

Add after `Tags/ExampleSyntax` section:
```yaml
Tags/ExampleStyle:
  Description: 'Validates code style in @example tags using RuboCop/StandardRB.'
  Enabled: false  # Opt-in validator (requires RuboCop or StandardRB)
  Severity: convention
  # Linter: auto  # Uncomment to explicitly configure: 'auto', 'rubocop', 'standard', 'none'
  # SkipPatterns:  # Uncomment to skip examples matching patterns
  #   - '/skip-lint/i'
  #   - '/bad code/i'
```

**File:** `lib/yard/lint/templates/strict_config.yml`

Add after `Tags/ExampleSyntax` section with same content (still disabled by default since it requires external gem).

## Verification Plan

### Manual Testing Steps

1. **Test with RuboCop project:**
   ```bash
   cd test-project-with-rubocop
   yard-lint lib/ --config .yard-lint.yml
   # Verify: RuboCop detected and used
   # Verify: Style offenses reported for examples
   ```

2. **Test with StandardRB project:**
   ```bash
   cd test-project-with-standard
   yard-lint lib/
   # Verify: StandardRB detected and used
   # Verify: StandardRB style offenses reported
   ```

3. **Test with neither installed:**
   ```bash
   cd test-project-without-linter
   DEBUG=1 yard-lint lib/
   # Verify: Debug message about missing linter
   # Verify: No crashes, graceful degradation
   ```

4. **Test skip patterns:**
   - Create example with "skip-lint" in name
   - Configure SkipPatterns
   - Verify: No offenses for skipped examples

5. **Test explicit linter configuration:**
   ```yaml
   Tags/ExampleStyle:
     Enabled: true
     Linter: rubocop  # Force RuboCop even if StandardRB available
   ```
   - Verify: RuboCop used despite StandardRB presence

6. **Test disabled cops:**
   - Create example with FrozenStringLiteralComment issue
   - Verify: Not reported (in default DisabledCops list)

### Automated Verification

Run test suite:
```bash
bundle exec rspec spec/yard/lint/validators/tags/example_style/
bundle exec rspec spec/integrations/example_style_spec.rb
```

Verify coverage:
```bash
bundle exec rspec --coverage
# Ensure new validator has >90% coverage
```

Integration test with yard-lint itself:
```bash
# Enable validator in .yard-lint.yml
bundle exec yard-lint lib/
# Verify: Works on yard-lint's own codebase
```

## Implementation Checklist

### Phase 1: Core Implementation
- [ ] Create module file `lib/yard/lint/validators/tags/example_style.rb`
- [ ] Create config class `lib/yard/lint/validators/tags/example_style/config.rb`
- [ ] Create linter detector `lib/yard/lint/validators/tags/example_style/linter_detector.rb`
- [ ] Create RuboCop runner `lib/yard/lint/validators/tags/example_style/rubocop_runner.rb`
- [ ] Create validator `lib/yard/lint/validators/tags/example_style/validator.rb`
- [ ] Create parser `lib/yard/lint/validators/tags/example_style/parser.rb`
- [ ] Create result `lib/yard/lint/validators/tags/example_style/result.rb`
- [ ] Create messages builder `lib/yard/lint/validators/tags/example_style/messages_builder.rb`

### Phase 2: Unit Tests
- [ ] Write LinterDetector specs
- [ ] Write RubocopRunner specs (with mocked RuboCop)
- [ ] Write Parser specs
- [ ] Write MessagesBuilder specs
- [ ] Write Result specs
- [ ] Write Validator specs

### Phase 3: Integration Tests
- [ ] Write integration test with RuboCop detection
- [ ] Write integration test with StandardRB detection
- [ ] Write integration test with skip patterns
- [ ] Write integration test with disabled cops
- [ ] Write integration test with no linter available
- [ ] Write integration test with multiple offenses

### Phase 4: Documentation
- [ ] Update README.md features list
- [ ] Add README.md section on ExampleStyle validator
- [ ] Update CHANGELOG.md
- [ ] Update `lib/yard/lint/templates/default_config.yml`
- [ ] Update `lib/yard/lint/templates/strict_config.yml`

### Phase 5: Manual Verification
- [ ] Test on project with RuboCop
- [ ] Test on project with StandardRB
- [ ] Test on project with neither
- [ ] Test skip patterns functionality
- [ ] Test explicit linter configuration
- [ ] Verify graceful degradation
- [ ] Run on yard-lint's own codebase

## Future Enhancements

These are NOT part of this implementation but could be added later:

1. **Auto-fix Support** (requires yard-lint --fix flag implementation)
   - Use RuboCop's `--autocorrect` feature
   - Update examples in place with style fixes

2. **Batch Processing Optimization**
   - Create temporary file with all examples
   - Run RuboCop once instead of per-example
   - Map results back to specific examples
   - Faster but more complex implementation

3. **Custom Cop Configuration Per Example**
   - Allow examples to specify which cops to enable/disable
   - Example: `@example (no-metrics)` to disable all Metrics cops

4. **Performance Caching**
   - Cache RuboCop config loading between examples
   - Reuse RuboCop::ConfigStore across invocations
   - Reduce overhead for projects with many examples

## Risk Assessment

**Low Risk Implementation:**
- ✅ No changes to existing validators
- ✅ No new hard dependencies in gemspec
- ✅ Graceful degradation when linter unavailable
- ✅ Opt-in by default (won't affect existing users)
- ✅ Follows established validator pattern exactly
- ✅ Clear separation of concerns

**Potential Issues:**
- ⚠️ Performance: RuboCop has ~200-500ms startup overhead per invocation
  - Mitigation: Only enabled for users who explicitly opt-in
  - Future: Batch processing optimization
- ⚠️ StandardRB doesn't support `--except` for individual cops
  - Mitigation: Document limitation, use .standard.yml for exclusions
- ⚠️ RuboCop version variations might have different JSON formats
  - Mitigation: Test with multiple versions, wrap parsing in error handling

## Dependencies

**Runtime (optional, not in gemspec):**
- `rubocop` gem (any version with --format json support, typically 1.0+)
- OR `standard` gem (any version, wraps RuboCop)

**Development:**
- None (use existing test infrastructure)

**Note:** We do NOT add RuboCop/StandardRB as dependencies to gemspec. They are optional runtime dependencies that users must install separately.

## Success Criteria

Implementation is successful when:

✅ Validator auto-detects RuboCop or StandardRB from project setup
✅ Respects project's RuboCop/StandardRB configuration
✅ Reports style offenses in code examples with clear messages
✅ Supports skip patterns for intentional bad examples
✅ Gracefully handles missing linter (no crashes, debug warning only)
✅ All unit tests pass with >90% coverage
✅ All integration tests pass
✅ Works on yard-lint's own codebase
✅ Documentation clearly explains setup and usage
✅ Default severity is 'convention'
✅ Disabled by default (opt-in)

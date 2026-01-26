# Announcing YARD-Lint: Keep Your Ruby Documentation Solid

I'm releasing [**YARD-Lint**](https://github.com/mensfeld/yard-lint), a comprehensive linter for YARD documentation in Ruby and Rails projects. It's available now as an open source gem.

```
# In your Gemfile
gem 'yard-lint'
```

For those unfamiliar, [YARD](https://yardoc.org/) (Yet Another Ruby Documentation) is a documentation tool for Ruby that uses structured tags - `@param`, `@return`, `@raise`, `@example` - to describe your methods with machine-readable precision. I prefer it because it's human-readable while staying structured enough for tools to process reliably.

I've been using YARD-Lint privately for a few years across all my OSS projects. I just haven't had time to package it properly until now. It's battle-tested across multiple production codebases and has caught thousands of documentation issues before they shipped.

## The Problem: Documentation Drift

Here's what kept happening:

- I'd refactor a method signature without updating the `@param` tags
- Return types changed, but `@return` tags stayed stale
- New exceptions got raised, but `@raise` tags weren't added
- Parameters got renamed, but the documentation lagged behind

Each drift created real problems. I'd return to code three months later and waste time figuring out what the method actually does versus what the docs claim. I'd make wrong assumptions based on outdated type signatures.

On top of that, I've noticed something interesting over the last year: documentation quality directly affects how useful AI coding assistants are. Well-documented modules with proper YARD tags? Claude Code gets it right on the first or second try. Poorly documented legacy code? I spend twice as long prompting, correcting, and refactoring.

Turns out [research validated exactly this](https://arxiv.org/html/2404.03114): incorrect documentation reduced LLM success rates by 50% (from 44.7% to 22.1%). [Enterprise studies at Zoominfo](https://arxiv.org/html/2501.13282v1) measured the same pattern: well-documented code shows 30%+ AI acceptance rates versus 14-20% for poorly documented code. But even without AI assistants, keeping docs in sync with code matters - YARD-Lint just became dramatically more valuable as these tools entered my daily workflows while ago.

## What YARD-Lint does

YARD-Lint ensures your YARD documentation remains accurate and complete. Among other things, it catches:

**Documentation drift** - Undocumented classes, modules, methods, and parameters that should have docs

**Type accuracy** - Invalid type definitions in `@param`, `@return`, and `@option` tags that don't match valid Ruby classes

**Missing context** - Methods with `options` parameters that lack `@option` tags, question mark methods without return type documentation

**Broken examples** - Invalid Ruby syntax in `@example` tags so your code samples actually work

**Semantic issues** - `@abstract` methods with actual implementations, inconsistent tag ordering

**YARD parser errors** - Unknown tags, invalid directives, duplicate parameters, malformed syntax

It's RuboCop for your documentation - automated validation that runs in CI and catches problems before they ship (with auto-fixing under development!).

## How to use it

Add it to your Gemfile:

```
# In your Gemfile
gem 'yard-lint'
```

Install it:

```bash
bundle exec yard-lint --init
```

Run it on your project:

```bash
bundle exec yard-lint app/
```

Add it to CI:

```yaml
# .github/workflows/lint.yml
- name: Run YARD Lint
  run: bundle exec yard-lint app/
```

Configure it with `.yard-lint.yml`:

```yaml
AllValidators:
  YardOptions:
    - --private
  Exclude:
    - 'vendor/**/*'
    - 'spec/**/*'

Documentation/UndocumentedObjects:
  Enabled: true
  Severity: warning

Tags/InvalidTypes:
  Enabled: true
  Severity: warning
```

It follows RuboCop's configuration style - hierarchical validators, inheritance support, per-validator controls. You can enable/disable specific checks, adjust severity levels, add custom type definitions, and exclude files per-validator.

## Gradual adoption

Don't want to fix 1,000 warnings before this becomes useful? You don't have to.

Use diff mode to only lint changed files:
```bash
# Only check files you modified (perfect for legacy codebases)
yard-lint app/ --diff main

# Or just staged files for pre-commit hooks
yard-lint lib/ --staged
```

Start small with config:
```
# Enable just one validator on your newest code
Documentation/UndocumentedObjects:
  Enabled: true
  Include:
    - 'lib/features/new_module/**/*'
```

Or exclude legacy code:
```
AllValidators:
  Exclude:
    - 'lib/legacy/**/*'
```

Many teams enable validators incrementally: start with diff mode on pull requests, gradually expand coverage, then tackle older code during refactoring.

## Why Open Source (and why now)

I've kept YARD-Lint private for years while constantly refining it. It reached a stable, production-ready state a while ago, but life got in the way - you know how it is.

Watching Ruby and Rails developers struggle with documentation drift - seeing teams waste time on outdated docs, seeing good documentation practices fade because there's no up to date automated validation for YARD users - I finally carved out time to properly package this up. If you're maintaining any serious Ruby codebase, you deserve automated documentation quality checks just like you have automated code quality checks.

---

**Good documentation saves time.** For your team, your tools, and your future self. Make sure it stays that way.

## References & Further Reading

**Research Studies:**
- [Testing the Effect of Code Documentation on Large Language Model Code Understanding](https://arxiv.org/html/2404.03114) - 2024 NAACL study on documentation impact
- [Experience with GitHub Copilot for Developer Productivity at Zoominfo](https://arxiv.org/html/2501.13282v1) - Enterprise deployment study with 400+ developers
- [Type-Constrained Code Generation with Large Language Models](https://openreview.net/pdf?id=DNAapYMXkc) - Research on type hints and generation accuracy

**Industry Best Practices:**
- [Five Best Practices for Using AI Coding Assistants](https://cloud.google.com/blog/topics/developers-practitioners/five-best-practices-for-using-ai-coding-assistants) - Google Cloud's documentation-first approach
- [How to Use GitHub Copilot in Your IDE: Tips, Tricks, and Best Practices](https://github.blog/developer-skills/github/how-to-use-github-copilot-in-your-ide-tips-tricks-and-best-practices/) - GitHub's official guidance
- [Effective Context Engineering for AI Agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) - Anthropic's recommendations for Claude

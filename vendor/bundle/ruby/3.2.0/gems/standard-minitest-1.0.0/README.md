# standard-minitest

This gem provides a [lint_roller](https://github.com/standardrb/lint_roller)
plugin configuration for the
[rubocop-minitest](https://github.com/rubocop/rubocop-minitest) ruleset, for use
as an extension to the [Standard Ruby
gem](https://github.com/standardrb/standard).

To install it, you'll want to start by adding it to your Gemfile:

```ruby
gem "standard-minitest"
```

## Configuration

In your `.standard.yml` file, you can simply list `standard-minitest` as a plugin:

```yaml
plugins:
  - standard-minitest
```

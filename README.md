# `dorian-eval`

Evaluate Ruby snippets and capture stdout, stderr, and return values.

## Install

```bash
gem install dorian-eval
```

Also included in the aggregate gem:

```bash
gem install dorian
```

## Usage

```bash
eval [options] "ruby code"
```

Run `eval -h` for generated option details and `eval -v` for the installed version.

## Notes

- The library exposes `Dorian::Eval.eval`. The executable prints the returned result object.

## Examples

### Evaluate and return a value

```bash
eval "1 + 1" --returns
```

### Use as a library

```ruby
require "dorian/eval"

result = Dorian::Eval.eval(ruby: "1 + 1", fast: true)
result.returned # => 2
```

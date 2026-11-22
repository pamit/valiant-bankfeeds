## Setup

Requires Ruby 4.0.10+ and Bundler.

```sh
bundle install
```

## Running the script

```sh
bundle exec thor statement:analyse fixtures/mary_and_tom_jones.json
bundle exec thor list            # shows available commands
```

The report is printed in colour (when stdout is a terminal) and a plain-text copy is written to `analysis.txt`, overwritten on each run. Use `--output` to choose another path.

The command exits with status 1 and an `error:` message for a missing file, invalid JSON, an illion error payload, or a payload without bank data.

## Running the tests

```sh
bundle exec rspec
bundle exec rspec spec/bank_statement/parser_spec.rb   # a single file
```

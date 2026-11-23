# Valiant Senior Backend Engineer technical test

## Repo structure

```text
.
├── docs/
│   └── diagrams/                # SYSTEM DESIGN: C4 + SEQUENCE
├── fixtures/
├── lib/
│   ├── bank_statement.rb        # Entry point: parse, run calculations, render report
│   └── bank_statement/
│       ├── cli.rb               # Thor CLI
│       ├── parser.rb            # Parses BankFeeds JSON shape
│       ├── statement.rb         # Statement (accounts + decision metrics), DecisionMetric
│       ├── account.rb
│       ├── transaction.rb
│       ├── report.rb            # Lays out header, category groups and pending; each result renders itself
│       ├── formatter.rb         # Shared colour, money and illion metric formatting
│       └── calculations/        # Grouped by the test's categories
│           ├── account_aggregation/
│           │   └── average_monthly_sales.rb
│           ├── risk_and_expenditure/
│           │   ├── gambling_percentage.rb
│           └── loan_metrics/
│               └── repayments_by_institution.rb
├── spec/
├── Dockerfile
├── docker-compose.yml           # dev-cli service
├── Makefile
├── Gemfile
├── Thorfile
└── CHANGELOG.md
```

## Task 1: System design

The system design documents can be found under `docs/diagrams`. C4 modelling is used to model users, systems, and system components.

## Task 2: Data processing

The script and the calculations logic code can be found in `lib`, with data models, reporting utilities, and the main calculations.

## Setup

Requires Ruby 4.0.10+ and Bundler.

```sh
bundle install
```

Or use Docker, with no local Ruby, PostgreSQL, Redis needed:

```sh
make build     # build the dev-cli image
make cli       # bash shell in the container
make test      # bundle exec rspec
make lint      # bundle exec rubocop; pass flags with ARGS="-a"
make console   # irb with the app loaded
docker compose run --rm dev-cli bundle exec thor statement:analyse fixtures/mary_and_tom_jones.json
```

The repo is mounted into the container, so code changes don't need a rebuild. Rebuild after changing the `Gemfile`.

## Running the script

```sh
bundle exec thor list            # shows available commands
bundle exec thor statement:analyse fixtures/mary_and_tom_jones.json
bundle exec thor statement:analyse fixtures/mary_and_tom_jones.json --output report.txt
```

The report is printed in colour (when stdout is a terminal) and a plain-text copy is written to `analysis.txt`, overwritten on each run.

The command exits with status 1 and an `error:` message for a missing file, invalid JSON, an illion error payload, or a payload without bank data.

## Running the tests

```sh
bundle exec rspec
bundle exec rubocop
```

## Design

- `Parser` turns the raw payload into immutable `Statement`, `Account` and `Transaction` values.
- `Transaction` is our normalised model. illion sends `date`, `description`, a signed `amount`, `type`, `balance`, and a `tags` array of hashes such as `{"category": "Wages"}` and `{"creditDebit": "credit"}`. The parser maps `creditDebit` to `credit_debit` and the `category` tags to `categories`, and stores `amount` as a positive `BigDecimal`.
- Each calculation in `lib/bank_statement/calculations/` takes a `Statement` and returns a result value. Adding one means adding a new class and registering it in `BankStatement::CALCULATIONS`.

### Assumptions

- Pending transactions are skipped as their amounts can change before they settle, but the script prints them. Informatonal rows are also skipped (with $0).
- Gambling winnings are not expenditure, so only gambling debits count. They shouldn't be counted as income either.
- Transactions are matched on illion's `category` tag first, then on their description, because many rows are untagged or have generic tags. Unclassified credeit transactions count as sales.

### Architecture

- BankFeeds calls run in schedulers (Sidekiq) with timeouts/retries, web requests enqueue and return `202`.
- The frontend app polls `GET /bank_connections/:id` or can subscribe over Action Cable (WebSockets) for status.
- The only security BankFeeds provides is HTTPS (error 30202) and a whitelist of allowed callback URLs (error 30203). The API docs mention no request signing. So the current design includes these checks:
  - a random one-off token in each callback URL, e.g. `/callback?token=yvx1j83` using `SecureRandom.alphanumeric(7, chars: [...])`
  - an allowlist of illion's IP addresses
  - best option: callback is only a signal and customer data must be fetched via the API, so a forged POST can't inject invalid transactions

### Re-rendering diagrams

```sh
npx -y @mermaid-js/mermaid-cli -i docs/diagrams/mermaid.md \
  -o docs/diagrams/architecture.png -e png -s 2 -p docs/diagrams/puppeteer.json
```

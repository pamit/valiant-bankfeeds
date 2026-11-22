.PHONY: build cli test lint console

RUN = docker compose run --rm dev-cli

build:
	docker compose build

cli:
	$(RUN)

test:
	$(RUN) bundle exec rspec

lint:
	$(RUN) bundle exec rubocop $(ARGS)

web:
	docker compose run web

console:
	$(RUN) irb -r ./lib/bank_statement

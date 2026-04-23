.PHONY: test test-unit test-integration test-e2e

## Run the full test suite (requires bats-core: brew install bats-core)
## Unit and integration tests use a docker shim; e2e tests require a real Docker daemon.
test:
	bats tests/unit tests/integration tests/e2e

## Run unit tests only (no Docker required)
test-unit:
	bats tests/unit

## Run unit + shimmed integration tests (no Docker required)
test-integration:
	bats tests/unit tests/integration

## Run E2E tests only (real Docker daemon required; tests skip if Docker is unavailable)
test-e2e:
	bats tests/e2e
